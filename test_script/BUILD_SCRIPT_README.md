# Simple Docker Build Script

A simple automated build script that detects your processor architecture and builds the appropriate Docker images using the same tags as specified in the main README.md.

## Usage

### Basic Build
```bash
./build.sh
```

### Clean Build (removes existing images first)
```bash
./build.sh --clean
```

### Help
```bash
./build.sh --help
```

## What It Does

The script automatically:

1. **Detects your architecture** (`uname -m`)
2. **Selects the correct Hadoop Dockerfile**:
   - ARM64 (Apple Silicon): Uses `hadoop_arm64/Dockerfile`
   - AMD64/x86_64: Uses root `Dockerfile`
3. **Builds all three images** with the exact same tags as in README.md:
   - `kennon/hadoop:hadoop_334` (Hadoop base)
   - `kennon/hadoop:spark_312` (Spark)
   - `kennon/hadoop:postgres-hms` (PostgreSQL Hive Metastore)

## Architecture Support

| Architecture | Hadoop Dockerfile | Notes |
|--------------|-------------------|-------|
| ARM64 (Apple Silicon) | `hadoop_arm64/Dockerfile` | For M1, M2, M3 Macs |
| AMD64/x86_64 | `Dockerfile` | For Intel/AMD processors |

## Images Built

The script builds exactly the same images referenced in docker-compose.yml:

- `kennon/hadoop:hadoop_334` - Hadoop 3.3.4 base image
- `kennon/hadoop:spark_312` - Spark 3.1.2 with Hadoop support  
- `kennon/hadoop:postgres-hms` - PostgreSQL Hive Metastore

## Requirements

- Docker installed and running
- Internet connection for downloading dependencies

## Example Output

```
[INFO] Detected architecture: arm64
[INFO] Using Hadoop Dockerfile: hadoop_arm64/Dockerfile
[INFO] Building Hadoop image...
[SUCCESS] Hadoop image built: kennon/hadoop:hadoop_334
[INFO] Building Spark image...
[SUCCESS] Spark image built: kennon/hadoop:spark_312
[INFO] Building PostgreSQL HMS image...
[SUCCESS] PostgreSQL HMS image built: kennon/hadoop:postgres-hms
[SUCCESS] All images built successfully!
```

After building, you can use `docker-compose up` to start the complete environment.