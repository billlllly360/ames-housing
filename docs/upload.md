# Uploading to GitHub

Create a repository named `ames-housing` and upload this folder's contents, not the parent workspace. If you use the GitHub website, choose **Add file → Upload files**.

Keep `data/`, `.R-library/` and `artifacts/` out of the upload. The folder contains only code, notes, result summaries and screenshots. Review the screenshots before publishing.

With Git:

```sh
git init
git add .
git status
git commit -m "Add housing price project"
git branch -M main
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

Replace the URL with your own repository. These commands have not been run for you. No code license has been chosen; add one if you want others to reuse the code.
