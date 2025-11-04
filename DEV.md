Development
===========

The `/framework` directory belongs to a separate [FG Add-on Framework](https://github.com/PlayeRom/flightgear-addon-framework) project, which has a separate git repository. The Framework is included in the project as a subtree.


## Adding Framework project to `/framework` directory (once only)

```bash
git remote add framework git@github.com:PlayeRom/flightgear-addon-framework.git
git subtree add --prefix=framework framework main --squash
```

**Note**: `--prefix` must be `framework`.

## Update Framework...

### ...with auto commit

```bash
git subtree pull --prefix=framework framework main --squash -m "Update framework"
```

## ...manually

```bash
git fetch framework main
git merge -s subtree --squash framework/main --allow-unrelated-histories
git diff
```

next commit changes:

```bash
git commit -m "Update framework"
```

or cancel changes:

```bash
git checkout -- framework
```
