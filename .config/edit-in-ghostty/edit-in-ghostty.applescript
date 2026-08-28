-- Finder default-editor droplet: opens dropped/double-clicked files as a new
-- tab in the existing Ghostty window (or a new window if none is open),
-- running nvim. Uses Ghostty's native AppleScript dictionary, not UI-scripting.
--
-- The nvim command is typed into a plain new tab via "input text" rather than
-- Ghostty's own surface-configuration "command" property, because that
-- property runs via a bare `bash --noprofile --norc` with no Homebrew PATH,
-- so `nvim` can't be found that way.

on open theFiles
    tell application "Ghostty"
        activate
        repeat with aFile in theFiles
            set posixPath to POSIX path of aFile
            if (count of windows) > 0 then
                set newTab to (new tab in front window)
            else
                set newWin to (new window)
                set newTab to selected tab of newWin
            end if
            delay 0.3
            set targetTerminal to focused terminal of newTab
            input text ("nvim " & quoted form of posixPath & linefeed) to targetTerminal
        end repeat
    end tell
end open

on run
    tell application "Ghostty" to activate
end run
