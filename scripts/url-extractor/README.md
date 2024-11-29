Find 3rd party urls both from vault and code. (I KNOW THIS IS VERY OLD-STYLE BUT WHATEVER)

You need to have a vault user that has a GET access to your vault's appConfig.
You need to have a git user that has pull access to your git repositories.
You need to place these scripts next to where there are lots of git projects.
You need your vault to have the same naming system as your git.
Use these data to update the script and make them usable.

How it works:
1. To just fetch vault records:
```
chmod +x vault-extractor.sh
./vault-extractor.sh
```

2. To just fetch hard-coded records:
```
chmod +x url-extractor.sh
./url-extractor.sh
```
