# Ghostscript AWS Lambda Layer
Build and publish an AWS Lambda Layer which provides `gs` command.

## Requirements
- Docker
- AWS CLI v2
- Node.js (npm)

## Release
The layer called `ghostscript-aws-lambda-layer` will be published with AWS CLI.

Copy `.env.release.example` to `.env.release`, and set the AWS account to publish to and the AWS CLI profile.
`.env.release` is not committed.

```sh
cp .env.release.example .env.release  # only for the first time
npm run release
```

The release stops if the credentials belong to another AWS account.
The description of the layer is generated from the version of the built `gs`, and the published layer version is printed at the end.

Publishing the layer does not change the Lambda functions that use it.
Update the layer version of the functions to use the new version.

## Usage
If you attach the layer to a lambda function, `gs` command will be installed under `/opt/bin`.

```sh
/opt/bin/gs --version
```

## License
Ghostscript is licensed under AGPL, and so is this project.
