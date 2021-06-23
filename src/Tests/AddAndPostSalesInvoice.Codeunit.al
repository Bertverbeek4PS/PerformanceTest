codeunit 81037 "Add&Post Sales Inv."
{
    Subtype = Test; //belangrijk dat functies afgaan maar gaat dan op de voorgrond

    trigger OnRun()
    begin
        InitTest; //vooraf instellingen goed zetten
    end;

    var
        IncludeUserWaits: Boolean;

    procedure InitTest()
    var
        LibraryInventory: Codeunit "PTK Library - Inventory 4PS";
        SalesReceivableSetup: Record "Sales & Receivables Setup";
    begin
        IncludeUserWaits := true;
        LibraryInventory.SetLocationMandatory(false);

        SalesReceivableSetup.Get;
        //Change the setup
        SalesReceivableSetup.Modify;
    end;

    [Test]
    procedure CreateAndPostSalesInvoice()
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        LibrarySales: Codeunit "PTK Library - Sales 4PS";
        LibraryRandom: Codeunit "PTK Library - Random 4PS";
        SalesHeader: Record "Sales Header";
        Customer: Record Customer;
    begin
        //Create customer
        BCPTTestContext.StartScenario('Create Customer'); //begin van specifieke meting
        LibrarySales.CreateCustomer(Customer, true);
        BCPTTestContext.EndScenario('Create Customer'); //Einde van specifieke meting

        BCPTTestContext.UserWait(); //gebruikers simulatie + commit

        //Create Sales Invoice
        BCPTTestContext.StartScenario('Create Sales Invoice');
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.", true);
        BCPTTestContext.EndScenario('Create Sales Invoice');

        BCPTTestContext.UserWait();

        //Post Sales Invoice
        BCPTTestContext.StartScenario('Post Sales Invoice');
        SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");
        BCPTTestContext.EndScenario('Post Sales Invoice');
        BCPTTestContext.UserWait();
    end;


}