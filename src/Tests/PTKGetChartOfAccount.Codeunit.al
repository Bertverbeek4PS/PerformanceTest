codeunit 81041 "Get Chart Of Account WS"
{
    Subtype = Test;

    [Test]
    procedure GetChartOfAccountWs()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        GLAccount: Record "G/L Account";
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "PTK Library - Sales 4PS";
        Method: Option Get,Post,Patch;
        JsonResponse: JsonObject;
    begin
        GLAccount.Get('0071');
        BCPTTestContext.StartScenario('Get Chart Of Account WS');
        JsonResponse := LibraryGraphMgt.RequestMessage('ADMIN', 'JOMZV7kFLUWy8ozEJo5BV6hXJ5sC96tj+b4b4+l+8IQ=', CreateTargetURL(GLAccount."No."), Method::Get, '');
        BCPTTestContext.EndScenario('Get Chart Of Account WS');
        BCPTTestContext.UserWait();
    end;

    local procedure CreateTargetURL(ID: Text): Text
    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        exit(LibraryGraphMgt.CreateTargetURL(ID, Page::"Chart Of Accounts", 'Rekeningschema'));
    end;
}