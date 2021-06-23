codeunit 81027 "PTK Open Vend Open Entries"
{
    Subtype = Test;

    trigger OnRun()
    begin
        InitTest();
    end;

    local procedure InitTest()
    begin

    end;

    [Test]
    procedure OpenVendorLedgerEntries();
    var
        VendorLedgerEntries: TestPage "Vendor Ledger Entries";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        BCPTTestContext.StartScenario('Open Vendor Ledger Entries');
        VendorLedgerEntries.OpenView();
        BCPTTestContext.UserWait();
        BCPTTestContext.EndScenario('Open Vendor Ledger Entries');
    end;
}