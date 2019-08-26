# El Templito

El Templito is an AWS Lambda driven templating service. It takes a `.docx` template file with `MailMerge` fields in it, replaces the fields with the provided values and generates a `PDF` file from the rendered template.

The service is based on two Lambda functions with SQS buffers in front of them:

1. Renderer. Based on [Sablon](https://github.com/senny/sablon)
2. PDF Generator. Based on LibreOffice

## Building

```
# Build Functions
rake build

# Build Layers
rake build_layers
```

## Deploying

```
# Package
rake package[s3_bucket_name]

# Deploy
rake deploy[stack-name,environment]
```

## Testing

```
sam local invoke RendererLambdaFunction --event spec/fixtures/events/renderer_event.json --env-vars .env.json --skip-pull-image
```
