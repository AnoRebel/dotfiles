# current-size.yazi
show current folder size plugin for Yazi,

Asynchronous task loading without blocking the rendering of other components

![image](https://gitee.com/DreamMaoMao/current-size.yazi/assets/30348075/e713a59e-72ed-4127-8ded-d2a2e59f6eda)


# Install 

### Linux

```bash
git clone https://gitee.com/DreamMaoMao/current-size.yazi.git ~/.config/yazi/plugins/current-size.yazi
```

# Usage 

Add this to ~/.config/yazi/init.lua

```
require("current-size"):setup({
    equal_ignore = {"~","/","/home"}, -- full path match
	-- sub_ignore = {"~/deskenv/master","~/deskenv/dev"} -- sub path match
})
```

if you want listen for file changes to automatically update the status.
Add this to ~/.config/yazi/yazi.toml, `below the exists [plugin] modules`, like this
```
[plugin]

fetchers = [
	{ id = "current-size", name = "*/", run = "current-size", prio = "normal" },
	{ id = "current-size", name = "*", run = "current-size",prio = "normal" },
]
```
