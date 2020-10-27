# GitHub Action: Comment to PR on missing resource tags Terraform AWS Provider

This action runs [tflint](https://github.com/wata727/tflint) against terraform and looks to identify taggable resources that are missing the specified tags.

## Inputs

### `tags`

**Required**. A comma and space seperated list within a string e.g. `tags: "this, is, a, list, of, tags"`

### `tag-map`

Optional. The common name of the variable used for a map of tags e.g. `tag-map: "common_tags"`

### `github-token`

**Required**. Must be in form of `github_token: ${{ secrets.github_token }}`.

### `paths-to-terraform-dirs`

Optional. Comma seperated list of path(s) from root of project to terraform directories e.g. `path-to-terraform: " "terraform/deploy/, terraform/modules/"` 


## Example usage

```yml
on: [pull_request]
jobs:
  check-tags:
    name: check-tags
    runs-on: ubuntu-latest

    steps:
      - name: Clone repo
        uses: actions/checkout@master

      # Example
      - name: check-aws-tags
        uses: dwpdigital/action-check-aws-tags@master
        with:
          tags: "these, are, the, tags"
          tag-map: "common_tags"
          github-token: ${{ secrets.github_token }}
          path-to-terraform: "./terraform"     
```
