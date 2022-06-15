class ParamInfoItem {
    [string]$Name
    [string]$OriginalName
    [string]$ParameterType
    [string]$Description
    [string]$DefaultValue

    ParamInfoItem([string]$_name, [string]$_originalName, [string]$_paramType, [string]$_description) {
        $this.Name = $_name
        $this.OriginalName = $_originalName
        $this.ParameterType = $_paramType
        $this.Description = $_description
    }

    ParamInfoItem([string]$_name, [string]$_originalName, [string]$_paramType, [string]$_description, [string]$_defaultValue) {
        $this.Name = $_name
        $this.OriginalName = $_originalName
        $this.ParameterType = $_paramType
        $this.Description = $_description
        $this.DefaultValue = $_defaultValue
    }
}