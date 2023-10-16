# Portable TeXLive

## One-line installation script for TeXLive

```bash
bash -c "$(curl -fsLS https://github.com/zydou/texlive-portable/raw/main/install.sh)"
```

This will install a recent version of texlive at `$HOME/.local/texlive/YYYY`, where `YYYY` denotes the year of the texlive release. The installation will take a while, so please be patient.

## Advanced Installation

If you want to install a different texlive version, a different texlive scheme, or at a different directory, you can use the following command:

```bash
bash -c "$(curl -fsLS https://github.com/zydou/texlive-portable/raw/main/install.sh)" -- -t 2022 -s full -d "$HOME/.local/texlive"

# -t texlive year, defaults to 2022
# -s texlive scheme, default to full (Options: small, medium, large, full)
# -d texlive ROOT directory, default to $HOME/.local/texlive. Different texlive versions will be installed under this ROOT directory, e.g. $HOME/.local/texlive/2022, $HOME/.local/texlive/2021, etc.
```
