# Jernau

> The player of games

Runs ink stories until they run out

## Get Started

### Step 1 Install node.js

use [nvm] to install node

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
nvm install 20
nvm use 20
```

### Step 2 Install

```bash
npm install -g @little-bonsai/jernau
```

### Step 3 Run

```bash
jernau --ink story.ink
```

## Acknowledgements

This would not have been possible without the great work of

- [ink]
- [inkjs]

## Contributing

Bug Reports and PRs are very welcome.

## Todo

- [ ] seeded random
- [ ] validation hooks
- [ ] externals binding
- [ ] output save file

[prettier]: https://prettier.io/
[ink]: https://github.com/inkle/ink/
[nvm]: https://github.com/nvm-sh/nvm
[inkjs]: https://github.com/y-lohse/inkjs
[web app]: https://bonsai.li/ballpoint
