# nixflakes

## NOTE!

- If you move the files from here to another folder you need to "git add" them first before "nix develop" will work!

- Delete the following file as it is automatically created ".config/starship.toml"
  - Don't create a script to automatically delete it as this will mess things up if you have several sessions open
    - and you constantly start and stop shells... shells will run without a config and default back to default settings

```
rm .config/starship.toml 
```

