# Network Topology



graph LR

&#x20;   DC\["FileServer01<br/>DC + DNS + File Server<br/>192.168.253.129"]

&#x20;   Client\["Pluto<br/>Workstation - Windows 11<br/>192.168.253.130"]

&#x20;   DC <--> Client

&#x20;   

&#x20;   style DC fill:#1565c0,stroke:#0d47a1,stroke-width:2px,color:#ffffff

&#x20;   style Client fill:#2e7d32,stroke:#1b5e20,stroke-width:2px,color:#ffffff



# AD Logical Structure



graph TD

&#x20;   Domain\["homelab.local"]

&#x20;   Domain --> USA\["OU=USA"]

&#x20;   USA --> Admin\["\_Admin"]

&#x20;   USA --> Groups\["Groups"]

&#x20;   USA --> Servers\["Servers"]

&#x20;   USA --> Users\["Users"]

&#x20;   USA --> Workstations\["Workstations"]

&#x20;   

&#x20;   Users --> Accounting

&#x20;   Users --> Executives

&#x20;   Users --> HR

&#x20;   Users --> IT

&#x20;   Users --> Marketing

&#x20;   Users --> Sales

&#x20;   

&#x20;   style Domain fill:#e65100,stroke:#bf360c,stroke-width:2px,color:#ffffff

&#x20;   style USA fill:#00695c,stroke:#004d40,stroke-width:2px,color:#ffffff

&#x20;   style Users fill:#2e7d32,stroke:#1b5e20,stroke-width:2px,color:#ffffff

&#x20;   style Admin fill:#424242,stroke:#212121,stroke-width:1px,color:#ffffff

&#x20;   style Groups fill:#424242,stroke:#212121,stroke-width:1px,color:#ffffff

&#x20;   style Servers fill:#424242,stroke:#212121,stroke-width:1px,color:#ffffff

&#x20;   style Workstations fill:#424242,stroke:#212121,stroke-width:1px,color:#ffffff



# AGDLP Access Chain



graph LR

&#x20;   User\["User Account<br/>(e.g. eshackleton)"]

&#x20;   Global\["Global Group<br/>IT"]

&#x20;   DL\["Domain Local Group<br/>DL\_IT\_Modify"]

&#x20;   Folder\["NTFS Permission<br/>Modify on C:\\CompanyData\\IT"]

&#x20;   

&#x20;   User -->|member of| Global

&#x20;   Global -->|nested in| DL

&#x20;   DL -->|granted on| Folder

&#x20;   

&#x20;   style User fill:#ad1457,stroke:#880e4f,stroke-width:2px,color:#ffffff

&#x20;   style Global fill:#1565c0,stroke:#0d47a1,stroke-width:2px,color:#ffffff

&#x20;   style DL fill:#e65100,stroke:#bf360c,stroke-width:2px,color:#ffffff

&#x20;   style Folder fill:#6a1b9a,stroke:#4a148c,stroke-width:2px,color:#ffffff

