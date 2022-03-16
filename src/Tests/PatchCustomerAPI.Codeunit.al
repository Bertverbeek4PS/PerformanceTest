codeunit 81040 "Patch Customer API"
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
        BodyJson: JsonObject;
        BodyTxt: Text;
        PTKLibraryRandom4PS: Codeunit "PTK Library - Random 4PS";
    begin
        LibrarySales.GetRandomCustomer(Customer);
        BodyJson.Add('name', PTKLibraryRandom4PS.RandText(50));
        BodyJson.WriteTo(BodyTxt);

        BCPTTestContext.StartScenario('Patch Customer API');
        JsonResponse := LibraryGraphMgt.RequestMessage(CreateTargetURL(Customer.SystemId), Method::Patch, BodyTxt);
        BCPTTestContext.EndScenario('Patch Customer API');
        BCPTTestContext.UserWait();
    end;

    local procedure CreateTargetURL(ID: Text): Text
    var
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
    begin
        exit(LibraryGraphMgt.CreateTargetURL(ID, Page::"Customer API 4PS", 'customers'));
    end;
}