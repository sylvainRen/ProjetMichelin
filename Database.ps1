
#$array = ((Get-Content G:\ProjetsZZ2F5\testSearch.txt)[1]) -split ';'

if($null -ne $args[0]){

    [xml]$Doc = New-Object System.Xml.XmlDocument
    $dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
    $root = $doc.CreateNode("element","Workspace",$null)

    $path = $PSScriptRoot + "\" + $args[0]

    #recuperation des frameworks
    $frameworks =  Get-ChildItem –Path $path | ?{ $_.PSIsContainer } | Select-Object Name,FullName
    foreach ($framework in $frameworks){

        $moduleNodes = @{}

        $f = $doc.CreateNode("element","Framework",$null)
        $f.SetAttribute("Name",$framework.Name)
    
 
       #Chemin des dossiers des interfaces
       $pathPublicInterfaces = $framework.FullName + "\PublicInterfaces"
       $pathProtectedInterfaces = $framework.FullName + "\ProtectedInterfaces"

       #Liste des interfaces du Framework selon qu'elles soient public ou protected
       if(Test-Path  $pathPublicInterfaces){
            $headerPublicInterfaces = Get-ChildItem –Path $pathPublicInterfaces -Filter '*.h'| Select-Object Name,FullName
       }
   
       if(Test-Path  $pathProtectedInterfaces){
            $headerProtectedInterfaces = Get-ChildItem –Path $pathProtectedInterfaces -Filter '*.h' | Select-Object Name,FullName
       }
   
       #Liste des modules du framework
       $modules = Get-ChildItem -Path $framework.FullName | ?{ $_.PSIsContainer } | Where-Object { ($_.Name -like '*.m') } | % { $_.Name} | % {$_.replace(".m","")}
   
       foreach($module in $modules){
   
           #header ou y a exportedby $module  
           $listHeadersByModule = @{}
           $listHeadersByModule[$module] = @()
       
           #liste des modules d'un framework 
           $moduleNode = $doc.CreateNode("element","Module",$null)
           $moduleNode.SetAttribute("Name", $module)
           $moduleNodes.Add($module, $moduleNode)
       }
   
       foreach($lm in $modules){
           $f.AppendChild($moduleNodes[$lm]) >$null
       }
   
   
       #Recuparation des modules associés au headers
       $regexGetModule = ' ExportedBy([^ ]*)'
   
        #Public headers by modules in framework
        if ($null -ne $headerPublicInterfaces)
        {
            foreach($header in $headerPublicInterfaces){
                $modulesPublicHeaders =  select-string -Path $header.FullName -Pattern $regexGetModule  | % { $_.Matches } | % { $_.Value} | % {$_.replace(" ExportedBy","")} | Get-unique              
                if ($null -ne $modulesPublicHeaders)
                {
                        foreach($module in $modulesPublicHeaders){
                            $listHeadersByModule[$module] += ,$header
                        }
                }
            
            }
        

        }
    
        #Protected headers by modules in framework
        if ($null -ne $headerProtectedInterfaces)
        {
            foreach($header in $headerProtectedInterfaces){
                $modulesProtectedHeaders =  select-string -Path $header.FullName -Pattern $regexGetModule  | % { $_.Matches } | % { $_.Value} | % {$_.replace(" ExportedBy","")} | Get-unique
                if ($null -ne $modulesProtectedHeaders)
                {
                         foreach($module in $modulesProtectedHeaders){
                            $listHeadersByModule[$module] += ,$header
                         }
                }   
            }
        }    


        #Creation XML pr les headers publics
        if ($null -ne $modulesPublicHeaders)
        {
            
            foreach($module in $modulesPublicHeaders){

                if ($null -ne $listHeadersByModule[$module])
                {

                        Write-Output $listHeadersByModule[$module]

                        $balisePublic = $doc.CreateNode("element","Public",$null)
                        foreach($h in $listHeadersByModule[$module]){
                            $baliseHeader = $doc.CreateNode("element","Header",$null)
                            $baliseHeader.SetAttribute("Name", $h.Name)
                            $baliseHeader.SetAttribute("Fullname", $h.FullName)
                            $balisePublic.AppendChild($baliseHeader) > $null
                        }
                        ($moduleNodes[$module]).AppendChild($balisePublic) > $null
                }
            }
       
        }
    
    
        #Creation XML pr les headers protected
        if ($null -ne $modulesProtectedHeaders)
        {
          

          foreach($module in $modulesProtectedHeaders){
                
                if ($null -ne $listHeadersByModule[$module])
                {
                        
                        $baliseProtected = $doc.CreateNode("element","Protected",$null)
                        foreach($h in $listHeadersByModule[$module]){
                            $baliseHeader = $doc.CreateNode("element","Header",$null)
                            $baliseHeader.SetAttribute("Name", $h.Name)
                            $baliseHeader.SetAttribute("Fullname", $h.FullName)
                            $baliseProtected.AppendChild($baliseHeader) > $null
                        }  
                        ($moduleNodes[$module]).AppendChild($baliseProtected) > $null
                }
           }
       
        }
        $root.AppendChild($f) > $null
    }

    $doc.AppendChild($dec) > $null
    $doc.AppendChild($root) > $null
    $doc.save($PSScriptRoot + "\" + $args[0] + "\Database.xml")

}
else{
    Write-Output "Le chemin du Workspace est manquant en argument"
}