codeunit 81029 "PTK Open Post. Puch. Inv. 4PS"
{
    Subtype = Test;

    [Test]
    procedure OpenServiceOrderCard()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
    begin
        Commit();

        BCPTTestContext.StartScenario('Open Posted Purchase Invoice Card');
        PostedPurchaseInvoice.OpenView();
        BCPTTestContext.EndScenario('Open Posted Purchase Invoice Card');
        PostedPurchaseInvoice.Close();
        BCPTTestContext.UserWait();
    end;
}