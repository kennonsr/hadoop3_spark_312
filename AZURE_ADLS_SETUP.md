# Azure Data Lake Storage Gen2 Configuration for Minimal Hive

This document provides step-by-step instructions for configuring the minimal Hive setup to use Azure Data Lake Storage Gen2 (ADLS) instead of local filesystem storage.

## Prerequisites

1. **Azure Storage Account** with Data Lake Storage Gen2 enabled
2. **Azure AD Application** with appropriate permissions
3. **Container** created in the storage account for Hive data
4. **Azure CLI** or Azure Portal access for configuration

## Azure Setup Steps

### 1. Create Azure Storage Account

```bash
# Using Azure CLI
az storage account create \
    --name <your-storage-account> \
    --resource-group <your-resource-group> \
    --location <your-location> \
    --sku Standard_LRS \
    --kind StorageV2 \
    --hierarchical-namespace true
```

### 2. Create Container

```bash
# Create container for Hive warehouse
az storage container create \
    --name hive-data \
    --account-name <your-storage-account>
```

### 3. Create Azure AD Application

```bash
# Create AD application
az ad app create --display-name "HiveMinimalApp"

# Create service principal
az ad sp create --id <app-id-from-previous-command>

# Assign Storage Blob Data Contributor role
az role assignment create \
    --assignee <service-principal-id> \
    --role "Storage Blob Data Contributor" \
    --scope "/subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Storage/storageAccounts/<storage-account>"
```

### 4. Get Required Values

You'll need these values for configuration:
- **Storage Account Name**: `<your-storage-account>`
- **Container Name**: `hive-data` (or your chosen name)
- **Client ID**: Application (client) ID from Azure AD app
- **Client Secret**: Client secret from Azure AD app
- **Tenant ID**: Directory (tenant) ID from Azure AD

## Configuration Steps

### Option 1: Environment Variables (Recommended)

1. **Create `.env` file** in your project root:

```bash
# Azure ADLS Configuration
AZURE_CLIENT_ID=your-client-id-here
AZURE_CLIENT_SECRET=your-client-secret-here
AZURE_TENANT_ID=your-tenant-id-here
AZURE_STORAGE_ACCOUNT=your-storage-account-name
AZURE_CONTAINER=hive-data
```

2. **Update docker-compose-minimal.yml**:

```yaml
# Uncomment these lines in the hive-server service
environment:
  - AZURE_CLIENT_ID=${AZURE_CLIENT_ID}
  - AZURE_CLIENT_SECRET=${AZURE_CLIENT_SECRET}
  - AZURE_TENANT_ID=${AZURE_TENANT_ID}
```

3. **Update hive-site-minimal.xml**:

```xml
<!-- Comment out local filesystem warehouse -->
<!--
<property>
   <name>hive.metastore.warehouse.dir</name>
   <value>file:///opt/hive/warehouse</value>
   <description>Local filesystem warehouse - Default for simple setup</description>
</property>
-->

<!-- Uncomment Azure ADLS warehouse -->
<property>
   <name>hive.metastore.warehouse.dir</name>
   <value>abfss://hive-data@yourstorageaccount.dfs.core.windows.net/hive/warehouse</value>
   <description>Azure ADLS Gen2 warehouse</description>
</property>
```

4. **Update core-site-minimal.xml**:

```xml
<!-- Uncomment Azure ADLS with Environment Variables section -->
<property>
  <name>fs.azure.account.auth.type.yourstorageaccount.dfs.core.windows.net</name>
  <value>OAuth</value>
</property>

<property>
  <name>fs.azure.account.oauth.provider.type.yourstorageaccount.dfs.core.windows.net</name>
  <value>org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider</value>
</property>

<property>
  <name>fs.azure.account.oauth2.client.id.yourstorageaccount.dfs.core.windows.net</name>
  <value>${env.AZURE_CLIENT_ID}</value>
</property>

<property>
  <name>fs.azure.account.oauth2.client.secret.yourstorageaccount.dfs.core.windows.net</name>
  <value>${env.AZURE_CLIENT_SECRET}</value>
</property>

<property>
  <name>fs.azure.account.oauth2.client.endpoint.yourstorageaccount.dfs.core.windows.net</name>
  <value>https://login.microsoftonline.com/${env.AZURE_TENANT_ID}/oauth2/token</value>
</property>
```

### Option 2: Direct Configuration (Less Secure)

Directly edit the configuration files with your actual values instead of environment variables.

**⚠️ Warning**: This method exposes secrets in configuration files. Use only for development.

## Deployment with Azure ADLS

### 1. Build and Run

```bash
# Load environment variables
source .env

# Build and run with Azure configuration
./build-minimal.sh --clean --run
```

### 2. Verify Azure Connection

```bash
# Connect to Hive
docker exec -it hive-server beeline -u "jdbc:hive2://localhost:10000/"

# Test table creation
CREATE TABLE azure_test (
    id INT,
    name STRING,
    created_date DATE
);

# Insert test data
INSERT INTO azure_test VALUES (1, 'test', '2024-01-01');

# Verify data
SELECT * FROM azure_test;

# Check table location (should show Azure path)
DESCRIBE FORMATTED azure_test;
```

### 3. Verify in Azure Portal

1. Go to your Storage Account in Azure Portal
2. Navigate to **Containers** → **hive-data**
3. You should see the Hive warehouse structure created

## Troubleshooting

### Common Issues

1. **Authentication Errors**
   ```
   ERROR: Unable to authenticate with Azure
   ```
   - Verify Client ID, Secret, and Tenant ID
   - Check Azure AD app permissions
   - Ensure Storage Blob Data Contributor role is assigned

2. **Container Not Found**
   ```
   ERROR: Container 'hive-data' not found
   ```
   - Verify container exists in storage account
   - Check container name in configuration

3. **Permission Denied**
   ```
   ERROR: Access denied to storage account
   ```
   - Verify role assignments
   - Check storage account firewall settings

### Debug Commands

```bash
# Check container logs
docker-compose -f docker-compose-minimal.yml logs hive-server

# Test Azure connectivity from container
docker exec -it hive-server bash
hdfs dfs -ls abfss://hive-data@yourstorageaccount.dfs.core.windows.net/
```

## Performance Considerations

### Azure ADLS vs Local Filesystem

| Aspect | Local Filesystem | Azure ADLS |
|--------|------------------|------------|
| **Performance** | Fastest | Network dependent |
| **Scalability** | Limited by disk | Virtually unlimited |
| **Durability** | Single point of failure | Highly durable |
| **Cost** | Storage only | Storage + transactions |
| **Backup** | Manual | Automatic |

### Optimization Tips

1. **Use larger block sizes** for better performance:
   ```xml
   <property>
     <name>fs.azure.block.size</name>
     <value>134217728</value> <!-- 128MB -->
   </property>
   ```

2. **Enable concurrent uploads**:
   ```xml
   <property>
     <name>fs.azure.block.upload.buffer.dir</name>
     <value>/tmp/azure-upload</value>
   </property>
   ```

3. **Use appropriate storage tier** (Hot/Cool/Archive) based on access patterns

## Migration from Local to Azure

### 1. Export Existing Data

```sql
-- Export table schemas
SHOW CREATE TABLE your_table;

-- Export data
INSERT OVERWRITE DIRECTORY '/tmp/export/your_table'
SELECT * FROM your_table;
```

### 2. Switch to Azure Configuration

Follow the configuration steps above.

### 3. Import Data to Azure

```sql
-- Recreate tables (they'll now use Azure ADLS)
CREATE TABLE your_table (...);

-- Import data
LOAD DATA LOCAL INPATH '/tmp/export/your_table' INTO TABLE your_table;
```

## Security Best Practices

1. **Use Managed Identity** when running in Azure (VM/Container Instances)
2. **Rotate secrets regularly**
3. **Use Azure Key Vault** for secret management in production
4. **Enable storage account firewall** to restrict access
5. **Use private endpoints** for enhanced security
6. **Monitor access logs** in Azure Monitor

## Cost Optimization

1. **Use lifecycle policies** to move old data to cooler tiers
2. **Monitor transaction costs** - frequent small operations can be expensive
3. **Use reserved capacity** for predictable workloads
4. **Clean up unused data** regularly

## Support and Resources

- [Azure Data Lake Storage Gen2 Documentation](https://docs.microsoft.com/en-us/azure/storage/blobs/data-lake-storage-introduction)
- [Hadoop Azure Support](https://hadoop.apache.org/docs/stable/hadoop-azure/index.html)
- [Hive on Azure Best Practices](https://docs.microsoft.com/en-us/azure/hdinsight/hive/apache-hive-warehouse-connector)

---

**Note**: Replace all placeholder values (`<your-storage-account>`, `your-client-id-here`, etc.) with your actual Azure configuration values.