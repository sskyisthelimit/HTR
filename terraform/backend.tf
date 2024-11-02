terraform { 
  cloud { 
    
    organization = "sskyisthelimit" 

    workspaces { 
      name = "htr-api-workspace" 
    } 
  } 
}