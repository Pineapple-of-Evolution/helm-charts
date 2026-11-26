# helm-charts

Mirror of the Helm charts we use. A push to `main` packages every chart under `charts/` and publishes a new version to GitHub Pages.

https://pineapple-of-evolution.github.io/helm-charts

```yaml
dependencies:
  - name: nxs-universal-chart
    version: 3.2.4
    repository: https://pineapple-of-evolution.github.io/helm-charts
```

Enable GitHub Pages for this repository from the `gh-pages` branch. Chart dependencies are vendored inside each chart, so a release does not fetch them again.
