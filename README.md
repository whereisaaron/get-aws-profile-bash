# get-aws-profile-bash

<!--
![Release](https://img.shields.io/github/release/whereisaaron/get-aws-profile-bash.svg)
-->

## Fetch AWS keys and secrets from a AWS credentials file

This is a pure bash script that can parse and extract AWS credentials (key id and secret) from a `~/.aws/credentials` file.

```bash
$ ./get-aws-profile.sh --help
Usage: ./get-aws-profile.sh [--credentials=<path>] [--profile=<name>] [--key|--secret|--session-token]

  Default --credentials is '~/.aws/credentials'
  Default --profile is 'default'

  By default environment variables are generated, e.g.
    source $(./get-aws-profile.sh --profile=myprofile)

  You can specify one of --key, --secret, -or --session-token to get just that value, with no line break:
    FOO_KEY=$(./get-aws-profile.sh --profile=myprofile --key)
    FOO_SECRET=$(./get-aws-profile.sh --profile=myprofile --secret)
    FOO_SESSION_TOKEN=$(./get-aws-profile.sh --profile=myprofile --session-token)
```

## Examples

### Set environment variables for 'my-example' profile

```bash
$ ./get-aws-profile.sh --profile my-example
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

$ eval $(./get-aws-profile.sh --profile my-example)
```

## Get key and secret for 'my-example' profile

```bash
$ ./get-aws-profile.sh --profile my-example --key
AKIAIOSFODNN7EXAMPLE

$ ./get-aws-profile.sh --profile my-example --secret
wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

$ export AWS_ACCESS_KEY_ID=$(./get-aws-profile.sh --profile my-example --key)
$ export AWS_SECRET_ACCESS_KEY=$(./get-aws-profile.sh --profile my-example --secret)
```

## Get key and secret for 'default' profile from a custom 'ini' file

```bash
$ ./get-aws-profile.sh --credentials /foo/bar/my-creds-file --key
AKIAIOSFODNN7EXAMPLE

$ ./get-aws-profile.sh --credentials /foo/bar/my-creds-file --secret
wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
```

## AWS Credentials file format

The AWS credentials file format appears to follow the old [Windows 'ini' file format](https://en.wikipedia.org/wiki/INI_file). Check the [AWS documentation](http://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html) for more information.

```ini
[default]
aws_access_key_id=AKIAIOSFODNN7EXAMPLE
aws_secret_access_key=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

[my-profile]
aws_access_key_id=AKIAI44QH8DHBEXAMPLE
aws_secret_access_key=je7MtGbClwBF/2Zp9Utk/h3yCo8nvbEXAMPLEKEY
```

## Rationale

I often need to include an AWS key id and secret in deployment scripts. Yet I don't want to actually include the credentials in the script or in the git repository.

Many AWS client tools support storing AWS credentials in the `~/.aws/credentials` file and using a `--profile` argument or `AWS_DEFAULT_PROFILE` environment variable. However other tools only work by setting the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables. Sometimes you need to inject these credentials into stored secrets or configurations.

This script helps script these tasks whilst keeping the credentials out of your scripts and repository. I wanted a pure bash solution I could include in automated build and deployment environments.

## Credits

The really cool part of this script is the ['ini' file parser written by Andres J. Diaz](https://web.archive.org/web/20180826221418/http://theoldschooldevops.com/2008/02/09/bash-ini-parser/).
