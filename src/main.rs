use lazy_static::lazy_static;
use regex::Regex;
use std::env;
use std::fs::OpenOptions;
use std::io::{self, Read, Write};
use std::process::{Command, Stdio};
use termion::event::Key;
use termion::input::TermRead;
use termion::raw::IntoRawMode;
use termion::{color, cursor, style};

const HINT_CHARS: &str = "asdfjkl;ghqweruio";
const MAX_MATCHES: usize = 26;

lazy_static! {
    static ref PATTERNS: Vec<Regex> = vec![
        // HTTPS/HTTP URLs
        Regex::new(r#"https?://[^\s<>"{}|\\^`\[\]]+"#).unwrap(),
        // File paths (absolute and relative, including ~)
        Regex::new(r"(?:~|\.{1,2})?/[a-zA-Z0-9._@\-/]+").unwrap(),
        // Git status --short output (files after status markers like " M", "??", "A ")
        Regex::new(r"^[\sMADRCU?!]{2,3}([^\s].+?)$").unwrap(),
        // ls -l output (filename at the end after date/time)
        Regex::new(r"^[drwx-]{10}.*[\d:]+\s+(.+)$").unwrap(),
        // PIDs from ps output (matches PID column in "F S UID PID ..." format)
        Regex::new(r"^\s*\d+\s+[A-Z]\s+\d+\s+(\d{3,7})\b").unwrap(),
        // Git SHA (7-40 chars)
        Regex::new(r"\b[0-9a-f]{7,40}\b").unwrap(),
        // IPv4 addresses
        Regex::new(r"\b(?:\d{1,3}\.){3}\d{1,3}\b").unwrap(),
    ];
}

#[derive(Debug, Clone)]
struct Match {
    text: String,
    line: usize,
    start: usize,
    end: usize,
    hint: char,
}

fn find_matches(content: &str, exclude_path: Option<&str>) -> Vec<Match> {
    let mut matches = Vec::new();
    let mut hint_idx = 0;

    for (line_num, line) in content.lines().enumerate() {
        if hint_idx >= MAX_MATCHES {
            break;
        }

        // Find all matches in this line
        for pattern in PATTERNS.iter() {
            for cap in pattern.captures_iter(line) {
                if hint_idx >= MAX_MATCHES {
                    break;
                }

                // Use capture group 1 if it exists, otherwise use the whole match (group 0)
                let matched = cap.get(1).or_else(|| cap.get(0)).unwrap();
                let text = matched.as_str().to_string();

                // Skip if this matches the current working directory (prompt path)
                if let Some(pwd) = exclude_path {
                    if text == pwd {
                        continue;
                    }
                }

                // Skip duplicates
                if matches.iter().any(|m: &Match| m.text == text) {
                    continue;
                }

                matches.push(Match {
                    text,
                    line: line_num,
                    start: matched.start(),
                    end: matched.end(),
                    hint: HINT_CHARS.chars().nth(hint_idx).unwrap(),
                });

                hint_idx += 1;
            }
        }
    }

    matches
}

fn render_overlay<W: Write>(content: &str, matches: &[Match], highlighted: Option<usize>, tty: &mut W) -> io::Result<()> {
    write!(tty, "{}{}", termion::clear::All, cursor::Hide)?;

    // Print original content
    for (i, line) in content.lines().enumerate() {
        write!(tty, "{}{}", cursor::Goto(1, (i + 1) as u16), line)?;
    }

    // Overlay hints
    for (idx, mat) in matches.iter().enumerate() {
        let x = (mat.start + 1) as u16;
        let y = (mat.line + 1) as u16;

        // Highlight the match
        if Some(idx) == highlighted {
            write!(
                tty,
                "{}{}{}{}{}",
                cursor::Goto(x, y),
                color::Bg(color::Yellow),
                color::Fg(color::Black),
                mat.text,
                style::Reset
            )?;
        }

        // Show hint after the match: " <- [hint]"
        let hint_x = (mat.end + 1) as u16;
        write!(
            tty,
            "{}{}{} <- [{}]{}",
            cursor::Goto(hint_x, y),
            color::Fg(color::Red),
            style::Bold,
            mat.hint,
            style::Reset
        )?;
    }

    tty.flush()?;
    Ok(())
}

fn run_selector(content: &str, exclude_path: Option<&str>) -> io::Result<Option<(String, bool)>> {
    // Find all matches
    let matches = find_matches(content, exclude_path);

    if matches.is_empty() {
        eprintln!("No matches found");
        return Ok(None);
    }

    // Open /dev/tty for terminal interaction
    let tty = OpenOptions::new()
        .read(true)
        .write(true)
        .open("/dev/tty")?;

    // Enter alternate screen and raw mode on the TTY
    let mut tty_raw = tty.try_clone()?.into_raw_mode()?;
    write!(tty_raw, "{}", termion::screen::ToAlternateScreen)?;
    tty_raw.flush()?;

    render_overlay(content, &matches, None, &mut tty_raw)?;

    // Input handling from TTY
    let tty_input = tty.try_clone()?;
    let mut selected: Option<&Match> = None;
    let mut should_paste = false;

    for key in tty_input.keys() {
        match key? {
            Key::Char('q') | Key::Esc => break,
            Key::Char(c) => {
                // Check if this matches a hint (lowercase)
                if let Some(mat) = matches.iter().find(|m| m.hint == c.to_ascii_lowercase()) {
                    selected = Some(mat);
                    // If capital letter was pressed, mark for paste
                    should_paste = c.is_ascii_uppercase();
                    break;
                }
            }
            _ => {}
        }
    }

    // Cleanup
    write!(tty_raw, "{}{}", cursor::Show, termion::screen::ToMainScreen)?;
    tty_raw.flush()?;
    drop(tty_raw);

    // Return selected text and paste flag
    Ok(selected.map(|mat| (mat.text.clone(), should_paste)))
}

fn run_tmux_mode() -> io::Result<()> {
    // Get pane information
    let pane_id = tmux_cmd(&["display-message", "-p", "#{pane_id}"])?;
    let pane_current_path = tmux_cmd(&["display-message", "-p", "#{pane_current_path}"])?;

    // Capture pane content
    let content = tmux_cmd(&["capture-pane", "-p", "-t", &pane_id])?;

    if content.trim().is_empty() {
        eprintln!("No content captured from pane");
        return Ok(());
    }

    // Run selector
    let result = run_selector(&content, Some(&pane_current_path))?;

    // Handle result
    if let Some((selected, should_paste)) = result {
        // Copy to tmux buffer
        let mut child = Command::new("tmux")
            .args(&["load-buffer", "-"])
            .stdin(Stdio::piped())
            .spawn()?;

        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(selected.as_bytes())?;
        }
        child.wait()?;

        // Paste if requested
        if should_paste {
            Command::new("tmux")
                .args(&["paste-buffer"])
                .status()?;
        } else {
            // Show message
            Command::new("tmux")
                .args(&["display-message", &format!("Copied: {}", selected)])
                .status()?;
        }
    }

    Ok(())
}

fn tmux_cmd(args: &[&str]) -> io::Result<String> {
    let output = Command::new("tmux")
        .args(args)
        .output()?;

    if !output.status.success() {
        return Err(io::Error::new(
            io::ErrorKind::Other,
            format!("tmux command failed: {:?}", args),
        ));
    }

    Ok(String::from_utf8_lossy(&output.stdout).trim().to_string())
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    // Check if running in tmux mode
    if args.len() > 1 && args[1] == "tmux" {
        return run_tmux_mode();
    }

    // Default mode: read from stdin and output selection
    let mut content = String::new();
    io::stdin().read_to_string(&mut content)?;

    if content.trim().is_empty() {
        eprintln!("No content received");
        return Ok(());
    }

    // Get current working directory to exclude from matches (often in prompt)
    let exclude_path = env::var("PWD").ok();

    // Run selector
    let result = run_selector(&content, exclude_path.as_deref())?;

    // Output selected text to stdout
    if let Some((text, should_paste)) = result {
        if should_paste {
            println!("PASTE:{}", text);
        } else {
            println!("{}", text);
        }
    }

    Ok(())
}
