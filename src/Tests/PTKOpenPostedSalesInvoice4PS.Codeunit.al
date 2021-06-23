codeunit 81030 "PTK Open Post. Sales Inv. 4PS"
{
    Subtype = Test;

    [Test]
    procedure OpenSalesOrderCard()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        PostedSalesInvoice: TestPage "Posted Sales Invoice";
    begin
        Commit();

        BCPTTestContext.StartScenario('Open Posted Sales Invoice Card');
        PostedSalesInvoice.OpenView();
        BCPTTestContext.EndScenario('Open Posted Sales Invoice Card');
        PostedSalesInvoice.Close();
        BCPTTestContext.UserWait();
    end;
}