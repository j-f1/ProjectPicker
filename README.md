# <img src="App Icon.png" width=30 height=30 alt="" align=center> ProjectPicker

An Alfred workflow for opening your projects.

## Installation

1. Install the workflow. Either [download it from GitHub](https://github.com/j-f1/ProjectPicker/raw/main/Project%20Picker.alfredworkflow) or follow the instructions below to build it yourself. Then, double-click the `Project Picker.alfredworkflow` file to install it.
2. Create a `project-picker.json` file in the `~/.config` folder (make sure to create the folder if it doesn’t exist). See the Configuration section below for what to put into it

## Configuration

The `project-picker.json` config file should have two top-level keys:

- `searchPaths`: An array of folders to search for project folders in, relative to your home directory. Any folders listed here will _not_ be available from Alfred. (for example, my `searchPaths` includes `Documents/github-clones`). Search paths are not recursive — only folders directly inside of a search path will be counted as projects.
- `apps`: The names of apps to launch. This must be an object with all of the following keys:
  - `default`: The name of the app to launch if the type of a given project could not be detected
  - `xcode`: The name of the app to launch for projects with a `*.xcodeproj`, `*.xcworkspace`, or `Package.swift` file  (such as `"Xcode"` or `"Xcode-beta"`)
  - `vscode`: The name of the app to launch for projects with a `*.code-workspace` file (such as `"Visual Studio Code"`)
  - `qtCreator`: The name of the app to launch for projects with a `*.pro` file (such as `"Qt Creator"`)

For more details on how the editor lookup works, check out the `Project.Kind.infer(from:)` method in `Project.swift`.

## Usage

After highlighting a project in Alfred, you can do the following things:
- Press <kbd>return</kbd> to open the project in the appropriate editor
- Press <kbd>⌘</kbd>+<kbd>return</kbd> to open the project folder in the Finder
- Press <kbd>⌥</kbd>+<kbd>return</kbd> to open the project folder in Terminal
- Press <kbd>🌐</kbd>+<kbd>return</kbd> to open the project in GitHub Desktop
- Press <kbd>⌃</kbd> to perform actions on the project folder using Alfred

## Building

With Xcode and the developer tools installed (`xcode-select --install`), run `./build.sh`. This will do the following tasks:

1. Build the binary in release mode, and place it inside of the `workflow` directory
2. Code-sign the resulting binary so it can run
3. Create the `Project Picker.alfredworkflow` file by zipping up the contents of the `workflow` directory
4. Notarize the resulting `Project Picker.alfredworkflow` file, and wait for it to finish.

The script may need tweaking, especially in the code signing and notarization steps, for your exact developer setup.
