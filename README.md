# DscBuildHelpers

DscBuildHelpers is a toolkit designed to assist with the compilation stage of Desired State Configuration (DSC) configurations and the lifecycle management of those configurations. This project provides various PowerShell functions and scripts to streamline the process of managing DSC resources and configurations.

## Features

- **Module Compression**: Compress DSC resource modules into zip files.
- **Module Deployment**: Inject missing DSC modules on a remote node via a PSSession.
- **Module Publishing**: Publish DSC resource modules to a pull server.
- **Dependency Resolution**: Resolve and install required modules for DSC configurations.
- **Resource Metadata Initialization**: Initialize metadata information for DSC resources.
- **Resource Property Retrieval**: Retrieve properties of DSC resources.
- **Configuration Compilation**: Compile DSC configurations and generate MOF files.
- **Integration with CI/CD**: Support for continuous integration and deployment using Azure Pipelines.

## Getting Started

### Prerequisites

- PowerShell 5.1 or higher.
- Required modules specified in [RequiredModules.psd1](./RequiredModules.psd1).

## Contributing

Please check out the common DSC Community [contributing guidelines](https://dsccommunity.org/guidelines/contributing).

## Running the Tests

For information on how to run the module's tests, refer to the [Testing Guidelines](https://dsccommunity.org/guidelines/testing-guidelines/#running-tests).

## Security

For security issues, please refer to the SECURITY.md

.

## License

This project is licensed under the MIT License. See the LICENSE file for details.

## Acknowledgments

Generated with Plaster and the SampleModule template.
