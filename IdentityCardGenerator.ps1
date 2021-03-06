if($null -ne $args[0]){

    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
    $path = $PSScriptRoot + "\" + $args[0]

    #recuperation des frameworks
    $frameworks =  Get-ChildItem –Path $path | ?{ $_.PSIsContainer } | Select-Object Name,FullName
    foreach ($framework in $frameworks){

        #declaration du xml de l'identityCard
        [xml]$Doc = New-Object System.Xml.XmlDocument
        $dec = $Doc.CreateXmlDeclaration("1.0","UTF-8",$null)
        $root = $doc.CreateNode("element","codeFramework",$null)
        $root.SetAttribute("xmlns","http://www.3ds.ic")
        $root.SetAttribute("xmlns:xsi","http://www.w3.org/2001/XMLSchema-instance")
        $root.SetAttribute("xsi:schemaLocation","http://www.3ds.ic ICModel.xsd")

        #recuperation des cpp
        $cppFiles =  Get-ChildItem –Path $path -Filter "*.cpp" -recurse | Select-Object Name,FullName
    
        #Recuparation des headers dans les cpps
        $regexGetHeader = '#include"(\w*).h"'
   
        #Public headers by modules in framework
        if ($null -ne $cppFiles)
        {
            foreach($cpp in $cppFiles){
                $includes = select-string -Path $cpp.FullName -Pattern $regexGetHeader  | % { $_.Matches } | % { $_.Value} | % {$_.replace('#include "',"")} | % {$_.replace('.h"',"")} | Get-unique
            }
        }
    
        #recherche dans la database des headers du framework
        [xml]$database = Get-Content -Path ($path + "\Database.xml")
        $xmlFram = $database.Workspace.Framework |  Where-Object { ($_.Name -like $framework.Name) }
        $xmlFram.Module.Public.Header
        $xmlFram.Module.Protected.Header
        

        if ($null -ne $includes){
            foreach($include in $includes){
                
            }
        }

        $doc.AppendChild($dec) > $null
        $doc.AppendChild($root) > $null
        $doc.save($framework.FullName + "\IdentityCard.xml")
    
        #TODO A chaque parcours de cpp ajouter un noeud pour l'IdentityCard si le header inclus n'est pas dans le framework 
        #Créer une identityCard dans chaque Framework
    }

}
else{
    Write-Output "Le chemin vers le workspace est manquant en argument"
}