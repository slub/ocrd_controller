# OCR-D Controller

> Path to network implementation of OCR-D

1. In the simplest (and current) form, the controller will be a SSH login server for a full [command-line](https://ocr-d.de/en/spec/cli) [OCR-D](https://ocr-d.de) [installation](https://github.com/OCR-D/ocrd_all). 
   Files must be mounted locally (if they are network shares, this must be done on the host side running the container).
2. Next, the SSH server can also dynamically receive and send data.
3. The first true network implementation will offer an HTTP interface for processing (like the [workflow server](https://github.com/OCR-D/core/pull/652)).
4. From there, the actual processing could be further delegated into different processing servers.
5. A more powerful workflow engine would then offer instantiating different workflows, and monitoring jobs.
6. In the final form, the controller will implement (most parts of) the OCR-D Web API.

 * [Usage](#usage)
   * [Building](#building)
   * [Starting and mounting](#starting-and-mounting)
   * [General management](#general-management)
   * [Processing](#processing)
     * [Workflow server](#workflow-server)
   * [Data transfer](#data-transfer)
   * [Parallel options](#parallel-options)
   * [Logging](#logging)
 * [See also](#see-also)


## Usage

### Building

Build or pull the Docker image:

    make build # or docker pull bertsky/ocrd_controller

### Starting and mounting

Then run the container – providing **host-side directories** for the volumes …

 * `DATA`: directory for data processing (including images or existing workspaces),  
   defaults to current working directory
 * `MODELS`: directory for persistent storage of processor [resource files](https://ocr-d.de/en/models),  
   defaults to `~/.local/share`; models will be under `./ocrd-resources/*`
 * `CONFIG`: directory for persistent storage of processor [resource list](https://ocr-d.de/en/models),  
   defaults to `~/.config`; file will be under `./ocrd/resources.yml`

… but also a file `KEYS` with public key **credentials** for log-in to the controller, and (optionally) some **environment variables** …

 * `WORKERS`: number of parallel jobs (i.e. concurrent login sessions for `ocrd`)
    (should be set to match the available computing resources)
 * `UID`: numerical user identifier to be used by programs in the container  
    (will affect the files modified/created); defaults to current user
 * `GID`: numerical group identifier to be used by programs in the container  
    (will affect the files modified/created); defaults to current group
 * `UMASK`: numerical user mask to be used by programs in the container  
    (will affect the files modified/created); defaults to 0002
 * `PORT`: numerical TCP port to expose the SSH server on the host side  
    defaults to 8022 (for non-priviledged access)
 * `NETWORK` name of the Docker network to use  
    defaults to `bridge` (the default Docker network)

… thus, for **example**:

    make run DATA=/mnt/workspaces MODELS=~/.local/share KEYS=~/.ssh/id_rsa.pub PORT=8022 WORKERS=3

### General management

Then you can **log in** as user `ocrd` from remote (but let's use `controller` in the following – 
without loss of generality):

    ssh -p 8022 ocrd@controller bash -i

Unless you already have the data in [workspaces](https://ocr-d.de/en/spec/glossary#workspace), 
you need to [**create workspaces**](https://ocr-d.de/en/user_guide#preparing-a-workspace) prior to processing.
For example:

    ssh -p 8022 ocrd@controller "ocrd-import -P some-document"

For actual processing, you will first need to [**download some models**](https://ocr-d.de/en/models)
into your `MODELS` volume:

    ssh -p 8022 ocrd@controller "ocrd resmgr download ocrd-tesserocr-recognize *"

### Processing

Subsequently, you can use these models on your `DATA` files:

    ssh -p 8022 ocrd@controller "ocrd process -m some-document/mets.xml 'tesserocr-recognize -P segmentation_level region -P model Fraktur'"
    # or equivalently:
    ssh -p 8022 ocrd@controller "ocrd-tesserocr-recognize -m some-document/mets.xml -P segmentation_level region -P model Fraktur"

#### Workflow server

Currently, the OCR-D installation hosts an implementation of the [workflow server](https://github.com/OCR-D/core/pull/652),
which can be used to significantly reduce initialization overhead when running the same workflow repeatedly
on many workspaces (especially with GPU-bound processors):

    ssh -p 8022 ocrd@controller "ocrd workflow server -j 4 -t 120 'tesserocr-recognize -P segmentation_level region -P model Fraktur'"

And subsequently:

    ssh -p 8022 ocrd@controller "ocrd workflow client process -m some-document/mets.xml"
    ssh -p 8022 ocrd@controller "ocrd workflow client process -m other-document/mets.xml"

### Data transfer

If your data files cannot be directly mounted on the host (not even as a network share),
then you can use `rsync`, `scp` or `sftp` to transfer them to the server:

    rsync --port 8022 -av some-directory ocrd@controller:/data
    scp -P 8022 -r some-directory ocrd@controller:/data
    echo put some-directory /data | sftp -P 8022 ocrd@controller

Analogously, to transfer the results back:

    rsync --port 8022 -av ocrd@controller:/data/some-directory .
    scp -P 8022 -r ocrd@controller:/data/some-directory .
    echo get /data/some-directory | sftp -P 8022 ocrd@controller

### Parallel options

For parallel processing, you can either
- run multiple processes on a single controller by
  - logging in multiple times, or 
  - issueing parallel commands – 
    * via basic shell scripting
    * via [ocrd-make](https://bertsky.github.io/workflow-configuration) calls
    * via [`ocrd workflow server --processes`](#workflow-server) concurrency
- run processes on multiple controllers.

Note: internally, `WORKERS` is implemented as a (GNU parallel-based) semaphore
wrapping the SSH sessions inside blocking `sem --fg` calls within .ssh/rc.
Thus, commands will get queued but not processed until a 'worker' is free.

### Logging

All logs are accumulated on standard output, which can be inspected via Docker:

    docker logs ocrd_controller

## See also

- [Meta-repo for integration of Kitodo.Production with OCR-D in Docker](https://github.com/markusweigelt/kitodo_production_ocrd)
- [Sister component OCR-D Manager](https://github.com/markusweigelt/ocrd_manager)
