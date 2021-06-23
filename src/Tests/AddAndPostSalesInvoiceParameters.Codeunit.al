codeunit 81036 "Add&Post Sales Inv. Parameter"
{
    Subtype = Test;

    trigger OnRun()
    begin
        InitTest;
    end;

    var
        IncludeUserWaits: Boolean;

    procedure InitTest()
    var
        LibraryInventory: Codeunit "PTK Library - Inventory 4PS";
    begin
        IncludeUserWaits := true;
        LibraryInventory.SetLocationMandatory(false);
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
        if BCPTTestContext.GetParameter('UseExistingData') = 'False' then begin
            BCPTTestContext.StartScenario('Create Customer');
            LibrarySales.CreateCustomer(Customer, true);
            BCPTTestContext.EndScenario('Create Customer');
        end else begin
            LibrarySales.GetRandomCustomer(Customer);
        end;

        BCPTTestContext.UserWait();

        BCPTTestContext.StartScenario('Create Sales Invoice');
        LibrarySales.CreateSalesInvoiceForCustomerNo(SalesHeader, Customer."No.", true);
        BCPTTestContext.EndScenario('Create Sales Invoice');

        BCPTTestContext.UserWait();

        if BCPTTestContext.GetParameter('Post') = 'True' then begin
            BCPTTestContext.StartScenario('Post Sales Invoice');
            SalesHeader.SendToPosting(CODEUNIT::"Sales-Post");
            BCPTTestContext.EndScenario('Post Sales Invoice');
            BCPTTestContext.UserWait();
        end;
    end;


}