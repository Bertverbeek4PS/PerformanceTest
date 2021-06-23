codeunit 80515 "PTK Test Param. Provider 4PS" implements "BCPT Test Param. Provider"
{
    procedure GetDefaultParameters(): Text[1000];
    begin
        exit('Budget Lines=1000,Installments=50,UseExistingData=False');
    end;

    procedure ValidateParameters(Params: Text[1000]);
    begin

    end;
}