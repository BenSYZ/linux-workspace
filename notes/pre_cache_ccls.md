```json
"ccls": {
            "command": "ccls",
            "filetypes": ["c", "cpp", "cuda", "objc", "objcpp"],
            //Unlike VSCode vim doesn't have workspace support. The solution is resolve workspace folders from opened files.
            //"args": ["--log-file=/tmp/ccls.log", "-v", "3"],
            // CocCommand workspace.workspaceFolders
            "rootPatterns": [".ccls", "compile_commands.json"], //, ".vim/", ".git/", ".hg/"
            "initializationOptions": {
                "cache": {
                    "directory": "${env:HOME}/.cache/ccls"
                }
            }
        },
```

```sh
ccls --index=. --init="{\"cache\": {\"directory\": \"$HOME/.cache/ccls\"}}" --log-file=/tmp/ccls_full_init.log -v=1
```
