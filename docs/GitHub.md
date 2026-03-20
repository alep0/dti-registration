# GitHub – Contributing and CI/CD

## Repository

```
https://github.com/aaaguado/dti-registration
```

Contact: aaaguado@ifisc.uib-csic.es

---

## Uploading to GitHub for the first time

```bash
cd dti-registration

git init
git branch -M main
git remote add origin https://github.com/alep0/dti-registration.git
git add .
#git reset
git status
git remote -v
git commit -m "Initial commit: DTI registration pipeline v1.0.0"
git remote set-url origin git@github.com:alep0/dti-registration.git
git push -u origin main

eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
git clone git@github.com:alep0/dti-registration.git
```

---

## Branch strategy

| Branch | Purpose |
|---|---|
| `main` | Stable, production-ready code |
| `dev` | Integration branch for new features |
| `feature/<name>` | Individual feature branches |
| `fix/<name>` | Bug-fix branches |

### Workflow

```bash
git checkout -b feature/my-improvement
# … make changes …
git add .
git commit -m "feat: describe the change"
git push origin feature/my-improvement
# Open a Pull Request on GitHub targeting `dev`
```

---

## Commit message convention

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short description>

[optional body]
```

Types: `feat`, `fix`, `docs`, `test`, `refactor`, `ci`, `chore`

---

## Continuous Integration (CI)

CI runs automatically on every push and pull request via GitHub Actions (`.github/workflows/ci.yml`).

### What CI checks

1. **Linting** – `flake8` style checks on all Python files.
2. **Type checking** – `mypy` on `source/`.
3. **Unit tests** – `pytest validations/` with coverage reporting.
4. **Shell linting** – `shellcheck` on all `.sh` files.

### Viewing CI results

Go to `https://github.com/aaaguado/dti-registration/actions`.

---

## Reporting issues

Open a GitHub Issue at:

```
https://github.com/aaaguado/dti-registration/issues
```

Or email: aaaguado@ifisc.uib-csic.es

Please include:
- Operating system and version
- Conda environment: `conda list > env_dump.txt`
- The relevant log file from `logs/`
- Steps to reproduce

---

## .gitignore summary

The following are excluded from version control:

- `data/` – raw experimental data (too large for Git)
- `results/` – pipeline outputs
- `logs/` – auto-generated log files
- `__pycache__/`, `*.pyc`, `.pytest_cache/`
- `.DS_Store`, `*.egg-info/`
- IDE folders (`.vscode/`, `.idea/`)
