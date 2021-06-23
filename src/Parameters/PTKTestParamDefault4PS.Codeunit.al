codeunit 80516 "PTK Test Param. Default 4PS" implements "BCPT Test Param. Provider"
{
    procedure GetDefaultParameters(): Text[1000];
    begin
        exit('Post=True,UseExistingData=False,Approve=False,WorkflowCode=');
    end;

    procedure ValidateParameters(Params: Text[1000]);
    begin

    end;
}