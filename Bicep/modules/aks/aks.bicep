param basename string

param identity object
param identityid string
param clientId string
param principalId string
param location string = resourceGroup().location
param podBindingSelector string
param podIdentityName string
param podIdentityNamespace string

//param logworkspaceid string  // Uncomment this to configure log analytics workspace

param subnetId string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2022-06-02-preview' = {
  name: '${basename}aks'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: identity   
  }
  properties: {
    kubernetesVersion: '1.26.3'
    nodeResourceGroup: '${basename}-aksInfraRG'
    dnsPrefix: '${basename}aks'
    agentPoolProfiles: [
      {
        name: 'default'
        count: 1
        vmSize: 'Standard_D4s_v3'
        mode: 'System'
        maxCount: 5
        minCount: 1
        osType: 'Linux'
        osSKU: 'Ubuntu'
        enableAutoScaling:true
        maxPods: 50
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: subnetId  // Uncomment this to configure VNET
        enableNodePublicIP:false
      }
    ]

    networkProfile: {
      loadBalancerSku: 'standard'
      networkPlugin: 'azure'
      outboundType: 'loadBalancer'
      dockerBridgeCidr: '172.17.0.1/16'
      dnsServiceIP: '10.0.0.10'
      serviceCidr: '10.0.0.0/16'
 
    }
    apiServerAccessProfile: {
      enablePrivateCluster: false
    }
    enableRBAC: true
    enablePodSecurityPolicy: false
    addonProfiles:{
      /*
	  // Uncomment this to configure log analytics workspace
	  omsagent: {
        config: {
          logAnalyticsWorkspaceResourceID: logworkspaceid
        }
        enabled: true
      }*/
      azureKeyvaultSecretsProvider: {
        enabled: true
      }
      azurepolicy: {
        enabled: false
      }
    }
    
    workloadAutoScalerProfile: {
      keda: {
        enabled: true
      }
      verticalPodAutoscaler: {
        controlledValues: 'RequestsAndLimits'
        enabled: true
        updateMode: 'Off'
      }
    }

    disableLocalAccounts: false
  }
}





///////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////

resource aksarmpool 'Microsoft.ContainerService/managedClusters/agentPools@2023-03-02-preview' = {
  name: 'armpool'
  parent: aksCluster
  properties: {
 
    count: 1
    enableAutoScaling: true
    enableNodePublicIP: false

    maxCount: 5
    minCount: 1
    maxPods: 50
    mode: 'user'

    nodeLabels: {}

    osSKU: 'AzureLinux'
    osType: 'Linux'
   
  
    tags: {}
    type: 'VirtualMachineScaleSets'

    vmSize: 'Standard_D2pds_v5'
    vnetSubnetID: subnetId
  }
}








