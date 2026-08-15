# ForestWatch — Microsoft Sentinel layer

Work in progress - first draft.

**Current stage:** the queries are tested in Azure Data Explorer cluster, as a way to introduce myself to KQL. Nothing is deployed to Microsoft Sentinel yet.

In this directory I'll re-implement the same techniques from ForestWatch to KQL for Microsoft Sentinel, so the same attacks can be compared across two different detection engines.

## Detections

| Technique               | Query                                                          | Wazuh rule  | Status      |
| ----------------------- | -------------------------------------------------------------- | ----------- | ----------- |
| T1558.003 Kerberoasting | [Kerberoasting.kql](./KQL/Kerberoasting_AzureDataExplorer.kql) | rule 100401 | in progress |
|                         |                                                                |             |             |
|                         |                                                                |             |             |
|                         |                                                                |             |             |
