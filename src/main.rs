use lazy_static::lazy_static;
use regex::Regex;
use std::fs::OpenOptions;
use std::io::{self, Read, Write};
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

fn find_matches(content: &str) -> Vec<Match> {
    let mut matches = Vec::new();
    let mut hint_idx = 0;

    for (line_num, line) in content.lines().enumerate() {
        if hint_idx >= MAX_MATCHES {
            break;
        }

        // Find all matches in this line
        for pattern in PATTERNS.iter() {
            for capture in pattern.find_iter(line) {
                if hint_idx >= MAX_MATCHES {
                    break;
                }

                let text = capture.as_str().to_string();

                // Skip duplicates
                if matches.iter().any(|m: &Match| m.text == text) {
                    continue;
                }

                matches.push(Match {
                    text,
                    line: line_num,
                    start: capture.start(),
                    end: capture.end(),
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

        // Show hint at the start of match
        write!(
            tty,
            "{}{}{}{}{}",
            cursor::Goto(x, y),
            color::Bg(color::Red),
            color::Fg(color::White),
            mat.hint,
            style::Reset
        )?;
    }

    tty.flush()?;
    Ok(())
}

fn main() -> io::Result<()> {
    // Read content from stdin
    let mut content = String::new();
    io::stdin().read_to_string(&mut content)?;

    if content.trim().is_empty() {
        eprintln!("No content received");
        return Ok(());
    }

    // Find all matches
    let matches = find_matches(&content);

    if matches.is_empty() {
        eprintln!("No matches found");
        return Ok(());
    }

    // Open /dev/tty for terminal interaction
    let mut tty = OpenOptions::new()
        .read(true)
        .write(true)
        .open("/dev/tty")?;

    // Enter alternate screen and raw mode on the TTY
    let mut tty_raw = tty.try_clone()?.into_raw_mode()?;
    write!(tty_raw, "{}", termion::screen::ToAlternateScreen)?;
    tty_raw.flush()?;

    render_overlay(&content, &matches, None, &mut tty_raw)?;

    // Input handling from TTY
    let tty_input = tty.try_clone()?;
    let mut selected: Option<&Match> = None;

    for key in tty_input.keys() {
        match key? {
            Key::Char('q') | Key::Esc => break,
            Key::Char(c) => {
                // Check if this matches a hint
                if let Some(mat) = matches.iter().find(|m| m.hint == c) {
                    selected = Some(mat);
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

    // Output selected text to stdout
    if let Some(mat) = selected {
        println!("{}", mat.text);
    }

    Ok(())
}
