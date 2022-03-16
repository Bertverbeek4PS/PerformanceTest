codeunit 81038 "Get Customer API"
{
    Subtype = Test;

    [Test]
    procedure GetCustomerAPI()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        Customer: Record Customer;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        LibrarySales: Codeunit "PTK Library - Sales 4PS";
        Method: Option Get,Post,Patch;
        JsonResponse: JsonObject;
    begin
        Customer.Get('10000');
        //LibrarySales.GetRandomCustomer(Customer);
        BCPTTestContext.StartScenario('Get Customer API');
        JsonResponse := LibraryGraphMgt.RequestMessage(CreateTargetURL(Customer.SystemId), Method::Get, '');
        BCPTTestContext.EndScenario('Get Customer API');
        BCPTTestContext.UserWait();
    end;

    local procedure CreateTargetURL(ID: Text): Text
    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        exit(LibraryGraphMgt.CreateTargetURL(ID, Page::"Customer API 4PS", 'customers'));
    end;
}