codeunit 80508 "PTK Library - Purchase 4PS"
{
    // Contains all utility functions related to Purchase.

    Permissions = TableData "Purchase Header" = rimd,
                  TableData "Purchase Line" = rimd;

    trigger OnRun()
    begin
    end;

    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Assert: Codeunit "PTK Assert 4PS";
        LibraryUtility: Codeunit "PTK Library - Utility 4PS";
        LibraryERM: Codeunit "PTK Library - ERM 4PS";
        LibraryInventory: Codeunit "PTK Library - Inventory 4PS";
        LibraryJournals: Codeunit "PTK Library - Journals 4PS";
        LibraryRandom: Codeunit "PTK Library - Random 4PS";

    procedure BlanketPurchaseOrderMakeOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchOrderHeader: Record "Purchase Header";
        BlanketPurchOrderToOrder: Codeunit "Blanket Purch. Order to Order";
    begin
        Clear(BlanketPurchOrderToOrder);
        BlanketPurchOrderToOrder.Run(PurchaseHeader);
        BlanketPurchOrderToOrder.GetPurchOrderHeader(PurchOrderHeader);
        exit(PurchOrderHeader."No.");
    end;

    procedure CopyPurchaseDocument(PurchaseHeader: Record "Purchase Header"; NewDocType: Option; NewDocNo: Code[20]; NewIncludeHeader: Boolean; NewRecalcLines: Boolean)
    var
        CopyPurchaseDocument: Report "Copy Purchase Document";
    begin
        CopyPurchaseDocument.SetPurchHeader(PurchaseHeader);
        CopyPurchaseDocument.InitializeRequest(NewDocType, NewDocNo, NewIncludeHeader, NewRecalcLines);
        CopyPurchaseDocument.UseRequestPage(false);
        CopyPurchaseDocument.Run;
    end;

    procedure CreateItemChargeAssignment(var ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)"; PurchaseLine: Record "Purchase Line"; ItemCharge: Record "Item Charge"; DocType: Enum "Purchase Applies-to Document Type"; DocNo: Code[20]; DocLineNo: Integer; ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal)
    var
        RecRef: RecordRef;
    begin
        Clear(ItemChargeAssignmentPurch);

        ItemChargeAssignmentPurch."Document Type" := PurchaseLine."Document Type";
        ItemChargeAssignmentPurch."Document No." := PurchaseLine."Document No.";
        ItemChargeAssignmentPurch."Document Line No." := PurchaseLine."Line No.";
        ItemChargeAssignmentPurch."Item Charge No." := PurchaseLine."No.";
        ItemChargeAssignmentPurch."Unit Cost" := PurchaseLine."Unit Cost";
        RecRef.GetTable(ItemChargeAssignmentPurch);
        ItemChargeAssignmentPurch."Line No." := LibraryUtility.GetNewLineNo(RecRef, ItemChargeAssignmentPurch.FieldNo("Line No."));
        ItemChargeAssignmentPurch."Item Charge No." := ItemCharge."No.";
        ItemChargeAssignmentPurch."Applies-to Doc. Type" := DocType;
        ItemChargeAssignmentPurch."Applies-to Doc. No." := DocNo;
        ItemChargeAssignmentPurch."Applies-to Doc. Line No." := DocLineNo;
        ItemChargeAssignmentPurch."Item No." := ItemNo;
        ItemChargeAssignmentPurch."Unit Cost" := UnitCost;
        ItemChargeAssignmentPurch.Validate("Qty. to Assign", Qty);
    end;

    procedure CreateOrderAddress(var OrderAddress: Record "Order Address"; VendorNo: Code[20])
    var
        PostCode: Record "Post Code";
    begin
        LibraryERM.CreatePostCode(PostCode);
        OrderAddress.Init;
        OrderAddress.Validate("Vendor No.", VendorNo);
        OrderAddress.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(OrderAddress.FieldNo(Code), DATABASE::"Order Address"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Order Address", OrderAddress.FieldNo(Code))));
        OrderAddress.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(OrderAddress.Name)));
        OrderAddress.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(OrderAddress.Address)));
        OrderAddress.Validate("Post Code", PostCode.Code);
        OrderAddress.Insert(true);
    end;

    procedure CreatePrepaymentVATSetup(var LineGLAccount: Record "G/L Account"; VATCalculationType: Enum "Tax Calculation Type"): Code[20]
    var
        PrepmtGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreatePrepaymentVATSetup(
          LineGLAccount, PrepmtGLAccount, LineGLAccount."Gen. Posting Type"::Purchase, VATCalculationType, VATCalculationType);
        exit(PrepmtGLAccount."No.");
    end;

    procedure CreatePurchasingCode(var Purchasing: Record Purchasing)
    begin
        Purchasing.Init;
        Purchasing.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(Purchasing.FieldNo(Code), DATABASE::Purchasing),
            1,
            LibraryUtility.GetFieldLength(DATABASE::Purchasing, Purchasing.FieldNo(Code))));
        Purchasing.Insert(true);
    end;

    procedure CreateDropShipmentPurchasingCode(var Purchasing: Record Purchasing)
    begin
        CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Drop Shipment", true);
        Purchasing.Modify(true);
    end;

    procedure CreateSpecialOrderPurchasingCode(var Purchasing: Record Purchasing)
    begin
        CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    procedure CreatePurchHeader(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; BuyfromVendorNo: Code[20]; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        DisableWarningOnCloseUnpostedDoc;
        DisableWarningOnCloseUnreleasedDoc;
        DisableConfirmOnPostingDoc;
        Clear(PurchaseHeader);
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader.Insert(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        if BuyfromVendorNo = '' then
            BuyfromVendorNo := CreateVendorNo(IncludeUserWait);
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyfromVendorNo);
        Commit;
        if PurchaseHeader."Document Type" in [PurchaseHeader."Document Type"::"Credit Memo",
                                              PurchaseHeader."Document Type"::"Return Order"]
        then
            PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID)
        else
            PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        SetCorrDocNoPurchase(PurchaseHeader);
        PurchaseHeader.Modify(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
    end;

    procedure CreatePurchHeaderWithDocNo(var PurchaseHeader: Record "Purchase Header"; DocumentType: Option; BuyfromVendorNo: Code[20]; DocNo: Code[20]; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        Clear(PurchaseHeader);
        PurchaseHeader.Validate("Document Type", DocumentType);
        PurchaseHeader."No." := DocNo;
        PurchaseHeader.Insert(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        if BuyfromVendorNo = '' then
            BuyfromVendorNo := CreateVendorNo(IncludeUserWait);
        PurchaseHeader.Validate("Buy-from Vendor No.", BuyfromVendorNo);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        SetCorrDocNoPurchase(PurchaseHeader);
        PurchaseHeader.Modify(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
    end;

    procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchaseLineSimple(PurchaseLine, PurchaseHeader, IncludeUserWait);

        PurchaseLine.Validate(Type, Type);
        case Type of
            PurchaseLine.Type::Item:
                if No = '' then
                    No := LibraryInventory.CreateItemNo(IncludeUserWait);
            PurchaseLine.Type::"Charge (Item)":
                if No = '' then
                    No := LibraryInventory.CreateItemChargeNo;
        end;
        PurchaseLine.Validate("No.", No);
        if Type <> PurchaseLine.Type::" " then
            PurchaseLine.Validate(Quantity, Quantity);
        PurchaseLine.Modify(true);

        OnAfterCreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, Quantity);
    end;

    procedure CreatePurchaseLineSimple(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        RecRef: RecordRef;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        PurchaseLine.Init;
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseLine);
        PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
        PurchaseLine.Insert(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
    end;

    procedure CreatePurchaseQuote(var PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        LibraryInventory: Codeunit "PTK Library - Inventory 4PS";
        LibraryRandom: Codeunit "PTK Library - Random 4PS";
        LibraryPurchase: Codeunit "PTK Library - Purchase 4PS";
        BCPTTestContext: Codeunit "BCPT Test Context";
        Vendor: Record Vendor;
    begin
        if BCPTTestContext.GetParameter('UseExistingData') = 'False' then begin
            CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, CreateVendorNo(IncludeUserWait), IncludeUserWait);
        end else begin
            LibraryPurchase.GetRandomVendor(Vendor);
            CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, Vendor."No.", IncludeUserWait);
        end;
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(IncludeUserWait), LibraryRandom.RandInt(100), IncludeUserWait);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 99, 2));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseInvoice(var PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        Vendor: Record Vendor;
    begin
        if BCPTTestContext.GetParameter('UseExistingData') = 'False' then begin
            CreatePurchaseInvoiceForVendorNo(PurchaseHeader, CreateVendorNo(IncludeUserWait), IncludeUserWait);
        end else begin
            Vendor.Reset;
            Vendor.FindLast();
            CreatePurchaseInvoiceForVendorNo(PurchaseHeader, Vendor."No.", IncludeUserWait);
        end;
    end;

    procedure CreatePurchaseInvoiceForVendorNo(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; IncludeUserWait: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo, IncludeUserWait);
        Vendor.Get(VendorNo);
        //CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo, LibraryRandom.RandInt(100), true);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
        Vendor: Record Vendor;
    begin
        if BCPTTestContext.GetParameter('UseExistingData') = 'False' then begin
            CreatePurchaseOrderForVendor(PurchaseHeader, CreateVendorNo(IncludeUserWait), IncludeUserWait);
        end else begin
            Vendor.Reset;
            Vendor.FindLast();
            CreatePurchaseOrderForVendor(PurchaseHeader, Vendor."No.", IncludeUserWait);
        end;
    end;

    procedure CreatePurchaseOrderForVendor(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; IncludeUserWait: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo, IncludeUserWait);
        Vendor.Get(VendorNo);
        //CreatePurchaseLine(
        //    PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNoWithPostingSetup(LookUpGenProdPostingGroup(),
        //    Vendor."VAT Prod. Posting Group", IncludeUserWait), LibraryRandom.RandInt(100), IncludeUserWait);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseCreditMemo(var PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", CreateVendorNo(IncludeUserWait), IncludeUserWait);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(IncludeUserWait), LibraryRandom.RandInt(100), IncludeUserWait);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; IncludeUserWait: Boolean)
    var
        PurchaseLine: Record "Purchase Line";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateVendorNo(IncludeUserWait), IncludeUserWait);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(IncludeUserWait), LibraryRandom.RandInt(100), IncludeUserWait);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchCommentLine(var PurchCommentLine: Record "Purch. Comment Line"; DocumentType: Option; No: Code[20]; DocumentLineNo: Integer; IncludeUserWait: Boolean)
    var
        RecRef: RecordRef;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        PurchCommentLine.Init;
        PurchCommentLine.Validate("Document Type", DocumentType);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchCommentLine.Validate("No.", No);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchCommentLine.Validate("Document Line No.", DocumentLineNo);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        RecRef.GetTable(PurchCommentLine);
        PurchCommentLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchCommentLine.FieldNo("Line No.")));
        PurchCommentLine.Insert(true);
        // Validate Comment as primary key to enable user to distinguish between comments because value is not important.
        PurchCommentLine.Validate(
          Comment, Format(PurchCommentLine."Document Type") + PurchCommentLine."No." +
          Format(PurchCommentLine."Document Line No.") + Format(PurchCommentLine."Line No."));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchCommentLine.Modify(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
    end;

    procedure CreatePurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date; IncludeUserWait: Boolean)
    begin
        CreateFCYPurchaseDocumentWithItem(
          PurchaseHeader, PurchaseLine, DocumentType, VendorNo, ItemNo, Quantity, LocationCode, ExpectedReceiptDate, '', IncludeUserWait);
    end;

    procedure CreateFCYPurchaseDocumentWithItem(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10]; ExpectedReceiptDate: Date; CurrencyCode: Code[10]; IncludeUserWait: Boolean)
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo, IncludeUserWait);
        if LocationCode <> '' then begin
            PurchaseHeader.Validate("Location Code", LocationCode);
            if IncludeUserWait then
                BCPTTestContext.UserWait();
        end;
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        PurchaseHeader.Modify(true);
        if ItemNo = '' then
            ItemNo := LibraryInventory.CreateItemNo(IncludeUserWait);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity, IncludeUserWait);
        if LocationCode <> '' then begin
            PurchaseLine.Validate("Location Code", LocationCode);
            if IncludeUserWait then
                BCPTTestContext.UserWait();
        end;
        if ExpectedReceiptDate <> 0D then begin
            PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
            if IncludeUserWait then
                BCPTTestContext.UserWait();
        end;
        PurchaseLine.Modify(true);
    end;

    procedure CreatePurchasePrepaymentPct(var PurchasePrepaymentPct: Record "Purchase Prepayment %"; ItemNo: Code[20]; VendorNo: Code[20]; StartingDate: Date)
    begin
        PurchasePrepaymentPct.Init;
        PurchasePrepaymentPct.Validate("Item No.", ItemNo);
        PurchasePrepaymentPct.Validate("Vendor No.", VendorNo);
        PurchasePrepaymentPct.Validate("Starting Date", StartingDate);
        PurchasePrepaymentPct.Insert(true);
    end;

    procedure CreateStandardPurchaseCode(var StandardPurchaseCode: Record "Standard Purchase Code")
    begin
        StandardPurchaseCode.Init;
        StandardPurchaseCode.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(StandardPurchaseCode.FieldNo(Code), DATABASE::"Standard Purchase Code"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Standard Purchase Code", StandardPurchaseCode.FieldNo(Code))));
        // Validating Description as Code because value is not important.
        StandardPurchaseCode.Validate(Description, StandardPurchaseCode.Code);
        StandardPurchaseCode.Insert(true);
    end;

    procedure CreateStandardPurchaseLine(var StandardPurchaseLine: Record "Standard Purchase Line"; StandardPurchaseCode: Code[10])
    var
        RecRef: RecordRef;
    begin
        StandardPurchaseLine.Init;
        StandardPurchaseLine.Validate("Standard Purchase Code", StandardPurchaseCode);
        RecRef.GetTable(StandardPurchaseLine);
        StandardPurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, StandardPurchaseLine.FieldNo("Line No.")));
        StandardPurchaseLine.Insert(true);
    end;

    procedure CreateSubcontractor(var Vendor: Record Vendor; IncludeUserWait: Boolean)
    begin
        CreateVendor(Vendor, IncludeUserWait);
    end;

    procedure CreateVendor(var Vendor: Record Vendor; IncludeUserWait: Boolean): Code[20]
    var
        PaymentMethod: Record "Payment Method";
        GeneralPostingSetup: Record "General Posting Setup";
        VATPostingSetup: Record "VAT Posting Setup";
        VendContUpdate: Codeunit "VendCont-Update";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        LibraryERM.FindPaymentMethod(PaymentMethod);
        LibraryERM.SetSearchGenPostingTypePurch;
        LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
        LibraryERM.FindVATPostingSetupInvt(VATPostingSetup);
        LibraryUtility.UpdateSetupNoSeriesCode(
          DATABASE::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Vendor Nos."));

        Clear(Vendor);
        Vendor.Insert(true);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate(Name, Vendor."No."); // Validating Name as No. because value is not important.
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("Gen. Bus. Posting Group", GeneralPostingSetup."Gen. Bus. Posting Group");
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        //Vendor.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group"); //**4PS.mg
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("Vendor Posting Group", FindVendorPostingGroup);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("Payment Terms Code", LibraryERM.FindPaymentTermsCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Modify(true);
        VendContUpdate.OnModify(Vendor);

        OnAfterCreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    procedure CreateVendorNo(IncludeUserWait: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, IncludeUserWait);
        exit(Vendor."No.");
    end;

    procedure CreateVendorPostingGroup(var VendorPostingGroup: Record "Vendor Posting Group")
    begin
        VendorPostingGroup.Init;
        VendorPostingGroup.Validate(Code,
          LibraryUtility.GenerateRandomCode(VendorPostingGroup.FieldNo(Code), DATABASE::"Vendor Posting Group"));
        VendorPostingGroup.Validate("Payables Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Service Charge Acc.", LibraryERM.CreateGLAccountWithPurchSetup);
        VendorPostingGroup.Validate("Invoice Rounding Account", LibraryERM.CreateGLAccountWithPurchSetup);
        VendorPostingGroup.Validate("Debit Rounding Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Credit Rounding Account", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Disc. Debit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Disc. Credit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Tolerance Debit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Payment Tolerance Credit Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Debit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Validate("Credit Curr. Appln. Rndg. Acc.", LibraryERM.CreateGLAccountNo);
        VendorPostingGroup.Insert(true);
    end;

    procedure CreateVendorWithLocationCode(var Vendor: Record Vendor; LocationCode: Code[10]; IncludeUserWait: Boolean): Code[20]
    var
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreateVendor(Vendor, IncludeUserWait);
        Vendor.Validate("Location Code", LocationCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateVendorWithBusPostingGroups(GenBusPostGroupCode: Code[20]; VATBusPostGroupCode: Code[20]; IncludeUserWait: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreateVendor(Vendor, IncludeUserWait);
        Vendor.Validate("Gen. Bus. Posting Group", GenBusPostGroupCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateVendorWithVATBusPostingGroup(VATBusPostGroupCode: Code[20]; IncludeUserWait: Boolean): Code[20]
    var
        Vendor: Record Vendor;
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreateVendor(Vendor, IncludeUserWait);
        Vendor.Validate("VAT Bus. Posting Group", VATBusPostGroupCode);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateVendorWithVATRegNo(var Vendor: Record Vendor; IncludeUserWait: Boolean): Code[20]
    var
        CountryRegion: Record "Country/Region";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        CreateVendor(Vendor, IncludeUserWait);
        LibraryERM.CreateCountryRegion(CountryRegion);
        Vendor.Validate("Country/Region Code", CountryRegion.Code);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor."VAT Registration No." := LibraryERM.GenerateVATRegistrationNo(CountryRegion.Code);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure CreateVendorWithAddress(var Vendor: Record Vendor; IncludeUserWait: Boolean)
    var
        PostCode: Record "Post Code";
        BCPTTestContext: Codeunit "BCPT Test Context";
    begin
        LibraryERM.CreatePostCode(PostCode);
        CreateVendor(Vendor, IncludeUserWait);
        Vendor.Validate(Name, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Name)));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate(Address, LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Address)));
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Validate("Post Code", PostCode.Code);
        if IncludeUserWait then
            BCPTTestContext.UserWait();
        Vendor.Contact := CopyStr(LibraryUtility.GenerateRandomText(MaxStrLen(Vendor.Contact)), 1, MaxStrLen(Vendor.Contact));
        Vendor.Modify(true);
    end;

    procedure CreateVendorBankAccount(var VendorBankAccount: Record "Vendor Bank Account"; VendorNo: Code[20])
    begin
        VendorBankAccount.Init;
        VendorBankAccount.Validate("Vendor No.", VendorNo);
        VendorBankAccount.Validate(
          Code,
          CopyStr(
            LibraryUtility.GenerateRandomCode(VendorBankAccount.FieldNo(Code), DATABASE::"Vendor Bank Account"),
            1,
            LibraryUtility.GetFieldLength(DATABASE::"Vendor Bank Account", VendorBankAccount.FieldNo(Code))));
        VendorBankAccount.Insert(true);
    end;

    procedure CreateVendorPurchaseCode(var StandardVendorPurchaseCode: Record "Standard Vendor Purchase Code"; VendorNo: Code[20]; "Code": Code[10])
    begin
        StandardVendorPurchaseCode.Init;
        StandardVendorPurchaseCode.Validate("Vendor No.", VendorNo);
        StandardVendorPurchaseCode.Validate(Code, Code);
        StandardVendorPurchaseCode.Insert(true);
    end;

    procedure CreatePurchaseHeaderPostingJobQueueEntry(var JobQueueEntry: Record "Job Queue Entry"; PurchaseHeader: Record "Purchase Header")
    begin
        JobQueueEntry.Init;
        JobQueueEntry.ID := CreateGuid;
        JobQueueEntry."Earliest Start Date/Time" := CreateDateTime(Today, 0T);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := CODEUNIT::"Purchase Post via Job Queue";
        JobQueueEntry."Record ID to Process" := PurchaseHeader.RecordId;
        JobQueueEntry."Run in User Session" := true;
        JobQueueEntry.Insert(true);
    end;

    procedure CreateIntrastatContact(CountryRegionCode: Code[10]; IncludeUserWait: Boolean): Code[20]
    var
        Vendor: Record Vendor;
    begin
        CreateVendor(Vendor, IncludeUserWait);
        Vendor.Validate(Name, LibraryUtility.GenerateGUID);
        Vendor.Validate(Address, LibraryUtility.GenerateGUID);
        Vendor.Validate("Country/Region Code", CountryRegionCode);
        Vendor.Validate("Post Code", LibraryUtility.GenerateGUID);
        Vendor.Validate(City, LibraryUtility.GenerateGUID);
        Vendor.Validate("Phone No.", Format(LibraryRandom.RandIntInRange(100000000, 999999999)));
        Vendor.Validate("Fax No.", LibraryUtility.GenerateGUID);
        Vendor.Validate("E-Mail", LibraryUtility.GenerateGUID + '@' + LibraryUtility.GenerateGUID);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    procedure DeleteInvoicedPurchOrders(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeader2: Record "Purchase Header";
        DeleteInvoicedPurchOrders: Report "Delete Invoiced Purch. Orders";
    begin
        if PurchaseHeader.HasFilter then
            PurchaseHeader2.CopyFilters(PurchaseHeader)
        else begin
            PurchaseHeader.Get(PurchaseHeader."Document Type", PurchaseHeader."No.");
            PurchaseHeader2.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseHeader2.SetRange("No.", PurchaseHeader."No.");
        end;
        Clear(DeleteInvoicedPurchOrders);
        DeleteInvoicedPurchOrders.SetTableView(PurchaseHeader2);
        DeleteInvoicedPurchOrders.UseRequestPage(false);
        DeleteInvoicedPurchOrders.RunModal;
    end;

    procedure ExplodeBOM(var PurchaseLine: Record "Purchase Line")
    var
        PurchExplodeBOM: Codeunit "Purch.-Explode BOM";
    begin
        Clear(PurchExplodeBOM);
        PurchExplodeBOM.Run(PurchaseLine);
    end;

    procedure FilterPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; DocumentType: Option; DocumentNo: Code[20]; DocNoOccurance: Integer; Version: Integer)
    begin
        PurchaseHeaderArchive.SetRange("Document Type", DocumentType);
        PurchaseHeaderArchive.SetRange("No.", DocumentNo);
        PurchaseHeaderArchive.SetRange("Doc. No. Occurrence", DocNoOccurance);
        PurchaseHeaderArchive.SetRange("Version No.", Version);
    end;

    procedure FilterPurchaseLineArchive(var PurchaseLineArchive: Record "Purchase Line Archive"; DocumentType: Option; DocumentNo: Code[20]; DocNoOccurance: Integer; Version: Integer)
    begin
        PurchaseLineArchive.SetRange("Document Type", DocumentType);
        PurchaseLineArchive.SetRange("Document No.", DocumentNo);
        PurchaseLineArchive.SetRange("Doc. No. Occurrence", DocNoOccurance);
        PurchaseLineArchive.SetRange("Version No.", Version);
    end;

    procedure FindVendorPostingGroup(): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        if not VendorPostingGroup.FindFirst then
            CreateVendorPostingGroup(VendorPostingGroup);
        exit(VendorPostingGroup.Code);
    end;

    procedure FindFirstPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst;
    end;

    procedure FindReturnShipmentHeader(var ReturnShipmentHeader: Record "Return Shipment Header"; ReturnOrderNo: Code[20])
    begin
        ReturnShipmentHeader.SetRange("Return Order No.", ReturnOrderNo);
        ReturnShipmentHeader.FindFirst;
    end;

    procedure GetDropShipment(var PurchaseHeader: Record "Purchase Header")
    var
        PurchGetDropShpt: Codeunit "Purch.-Get Drop Shpt.";
    begin
        Clear(PurchGetDropShpt);
        PurchGetDropShpt.Run(PurchaseHeader);
    end;

    procedure GetInvRoundingAccountOfVendPostGroup(VendorPostingGroupCode: Code[20]): Code[20]
    var
        VendorPostingGroup: Record "Vendor Posting Group";
    begin
        VendorPostingGroup.Get(VendorPostingGroupCode);
        exit(VendorPostingGroup."Invoice Rounding Account");
    end;

    procedure GetPurchaseReceiptLine(var PurchaseLine: Record "Purchase Line")
    var
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
    begin
        Clear(PurchGetReceipt);
        PurchGetReceipt.Run(PurchaseLine);
    end;

    procedure GetSpecialOrder(var PurchaseHeader: Record "Purchase Header")
    var
        DistIntegration: Codeunit "Dist. Integration";
    begin
        Clear(DistIntegration);
        DistIntegration.GetSpecialOrders(PurchaseHeader);
    end;

    procedure GegVendorLedgerEntryUniqueExternalDocNo(): Code[10]
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        exit(
          LibraryUtility.GenerateRandomCodeWithLength(
            VendorLedgerEntry.FieldNo("External Document No."),
            DATABASE::"Vendor Ledger Entry",
            10));
    end;

    procedure PostPurchasePrepaymentCrMemo(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
    begin
        PurchPostPrepayments.CreditMemo(PurchaseHeader);
    end;

    procedure PostPurchasePrepaymentCreditMemo(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchPostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := PurchaseHeader."Prepmt. Cr. Memo No. Series";
        if PurchaseHeader."Prepmt. Cr. Memo No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false)
        else
            DocumentNo := PurchaseHeader."Prepmt. Cr. Memo No.";
        PurchPostPrepayments.CreditMemo(PurchaseHeader);
    end;

    procedure PostPurchasePrepaymentInvoice(var PurchaseHeader: Record "Purchase Header") DocumentNo: Code[20]
    var
        PurchasePostPrepayments: Codeunit "Purchase-Post Prepayments";
        NoSeriesMgt: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        NoSeriesCode := PurchaseHeader."Prepayment No. Series";
        if PurchaseHeader."Prepayment No." = '' then
            DocumentNo := NoSeriesMgt.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false)
        else
            DocumentNo := PurchaseHeader."Prepayment No.";
        PurchasePostPrepayments.Invoice(PurchaseHeader);
    end;

    procedure PostPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; ToShipReceive: Boolean; ToInvoice: Boolean) DocumentNo: Code[20]
    var
        NoSeriesManagement: Codeunit NoSeriesManagement;
        NoSeriesCode: Code[20];
    begin
        // Post the purchase document.
        // Depending on the document type and posting type return the number of the:
        // - purchase receipt,
        // - posted purchase invoice,
        // - purchase return shipment, or
        // - posted credit memo
        SetCorrDocNoPurchase(PurchaseHeader);
        PurchaseHeader.Validate(Receive, ToShipReceive);
        PurchaseHeader.Validate(Ship, ToShipReceive);
        PurchaseHeader.Validate(Invoice, ToInvoice);

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Invoice:
                NoSeriesCode := PurchaseHeader."Posting No. Series"; // posted purchase invoice
            PurchaseHeader."Document Type"::Order:
                if ToShipReceive and not ToInvoice then
                    NoSeriesCode := PurchaseHeader."Receiving No. Series" // posted purchase receipt
                else
                    NoSeriesCode := PurchaseHeader."Posting No. Series"; // posted purchase invoice
            PurchaseHeader."Document Type"::"Credit Memo":
                NoSeriesCode := PurchaseHeader."Posting No. Series"; // posted purchase credit memo
            PurchaseHeader."Document Type"::"Return Order":
                if ToShipReceive and not ToInvoice then
                    NoSeriesCode := PurchaseHeader."Return Shipment No. Series" // posted purchase return shipment
                else
                    NoSeriesCode := PurchaseHeader."Posting No. Series"; // posted purchase credit memo
            else
                Assert.Fail(StrSubstNo('Document type not supported: %1', PurchaseHeader."Document Type"))
        end;

        if NoSeriesCode = '' then
            DocumentNo := PurchaseHeader."No."
        else
            DocumentNo :=
              NoSeriesManagement.GetNextNo(NoSeriesCode, LibraryUtility.GetNextNoSeriesPurchaseDate(NoSeriesCode), false);
        CODEUNIT.Run(CODEUNIT::"Purch.-Post", PurchaseHeader);
    end;

    procedure QuoteMakeOrder(var PurchaseHeader: Record "Purchase Header"): Code[20]
    var
        PurchaseOrderHeader: Record "Purchase Header";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
    begin
        Clear(PurchQuoteToOrder);
        PurchQuoteToOrder.Run(PurchaseHeader);
        PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrderHeader);
        exit(PurchaseOrderHeader."No.");
    end;

    procedure ReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.PerformManualRelease(PurchaseHeader);
    end;

    procedure ReopenPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        ReleasePurchDoc: Codeunit "Release Purchase Document";
    begin
        ReleasePurchDoc.PerformManualReopen(PurchaseHeader);
    end;

    procedure CalcPurchaseDiscount(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine."Document Type" := PurchaseHeader."Document Type";
        PurchaseLine."Document No." := PurchaseHeader."No.";
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
    end;

    procedure RunBatchPostPurchaseReturnOrdersReport(var PurchaseHeader: Record "Purchase Header")
    var
        BatchPostPurchRetOrders: Report "Batch Post Purch. Ret. Orders";
    begin
        Clear(BatchPostPurchRetOrders);
        BatchPostPurchRetOrders.SetTableView(PurchaseHeader);
        Commit;  // COMMIT is required to run this report.
        BatchPostPurchRetOrders.UseRequestPage(true);
        BatchPostPurchRetOrders.Run;
    end;

    procedure RunDeleteInvoicedPurchaseReturnOrdersReport(var PurchaseHeader: Record "Purchase Header")
    var
        DeleteInvdPurchRetOrders: Report "Delete Invd Purch. Ret. Orders";
    begin
        Clear(DeleteInvdPurchRetOrders);
        DeleteInvdPurchRetOrders.SetTableView(PurchaseHeader);
        DeleteInvdPurchRetOrders.UseRequestPage(false);
        DeleteInvdPurchRetOrders.Run;
    end;

    procedure RunMoveNegativePurchaseLinesReport(var PurchaseHeader: Record "Purchase Header"; FromDocType: Option; ToDocType: Option; ToDocType2: Option)
    var
        MoveNegativePurchaseLines: Report "Move Negative Purchase Lines";
    begin
        Clear(MoveNegativePurchaseLines);
        MoveNegativePurchaseLines.SetPurchHeader(PurchaseHeader);
        MoveNegativePurchaseLines.InitializeRequest(FromDocType, ToDocType, ToDocType2);
        MoveNegativePurchaseLines.UseRequestPage(false);
        MoveNegativePurchaseLines.Run;
    end;

    procedure SetAllowVATDifference(AllowVATDifference: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Allow VAT Difference", AllowVATDifference);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetAllowDocumentDeletionBeforeDate(Date: Date)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Allow Document Deletion Before", Date);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveQuotesAlways()
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Quotes", PurchasesPayablesSetup."Archive Quotes"::Always);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveOrders(ArchiveOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Orders", ArchiveOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveBlanketOrders(ArchiveBlanketOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Blanket Orders", ArchiveBlanketOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetArchiveReturnOrders(ArchiveReturnOrders: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Archive Return Orders", ArchiveReturnOrders);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDefaultPostingDateWorkDate()
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", PurchasesPayablesSetup."Default Posting Date"::"Work Date");
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDefaultPostingDateNoDate()
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", PurchasesPayablesSetup."Default Posting Date"::"No Date");
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDiscountPosting(DiscountPosting: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Discount Posting", DiscountPosting);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetDiscountPostingSilent(DiscountPosting: Option)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup."Discount Posting" := DiscountPosting;
        PurchasesPayablesSetup.Modify;
    end;

    procedure SetCalcInvDiscount(CalcInvDiscount: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetCorrDocNoPurchase(var PurchHeader: Record "Purchase Header")
    begin
        if PurchHeader."Document Type" in [PurchHeader."Document Type"::"Credit Memo", PurchHeader."Document Type"::"Return Order"] then;
    end;

    procedure SetInvoiceRounding(InvoiceRounding: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Invoice Rounding", InvoiceRounding);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetExactCostReversingMandatory(ExactCostReversingMandatory: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Exact Cost Reversing Mandatory", ExactCostReversingMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetExtDocNo(ExtDocNoMandatory: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Ext. Doc. No. Mandatory", ExtDocNoMandatory);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetPostWithJobQueue(PostWithJobQueue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Post with Job Queue", PostWithJobQueue);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetPostAndPrintWithJobQueue(PostAndPrintWithJobQueue: Boolean)
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Post & Print with Job Queue", PostAndPrintWithJobQueue);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetOrderNoSeriesInSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetPostedNoSeriesInSetup()
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Posted Invoice Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Receipt Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Credit Memo Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetQuoteNoSeriesInSetup()
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Quote Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetReturnOrderNoSeriesInSetup()
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Validate("Posted Return Shpt. Nos.", LibraryERM.CreateNoSeriesCode);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SetCopyCommentsOrderToInvoiceInSetup(CopyCommentsOrderToInvoice: Boolean)
    begin
        PurchasesPayablesSetup.Get;
        PurchasesPayablesSetup.Validate("Copy Comments Order to Invoice", CopyCommentsOrderToInvoice);
        PurchasesPayablesSetup.Modify(true);
    end;

    procedure SelectPmtJnlBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, SelectPmtJnlTemplate);
    end;

    procedure SelectPmtJnlTemplate(): Code[10]
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalTemplateType: Enum "Gen. Journal Template Type";
    begin
        exit(LibraryJournals.SelectGenJournalTemplate(GenJournalTemplateType::Payments, PAGE::"Payment Journal"));
    end;

    procedure UndoPurchaseReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Purchase Receipt Line", PurchRcptLine);
    end;

    procedure UndoReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line")
    begin
        CODEUNIT.Run(CODEUNIT::"Undo Return Shipment Line", ReturnShipmentLine);
    end;

    procedure DisableConfirmOnPostingDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
    begin
        InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.ShowPostedConfirmationMessageCode);
    end;

    procedure DisableWarningOnCloseUnreleasedDoc()
    begin
        LibraryERM.DisableClosingUnreleasedOrdersMsg;
    end;

    procedure DisableWarningOnCloseUnpostedDoc()
    var
        InstructionMgt: Codeunit "Instruction Mgt.";
        UserPreference: Record "User Preference";
    begin
        if not UserPreference.Get(UserId, InstructionMgt.QueryPostOnCloseCode) then //**4PS
            InstructionMgt.DisableMessageForCurrentUser(InstructionMgt.QueryPostOnCloseCode);
    end;

    procedure EnablePurchSetupIgnoreUpdatedAddresses()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get;
        PurchSetup."Ignore Updated Addresses" := true;
        PurchSetup.Modify;
    end;

    procedure DisablePurchSetupIgnoreUpdatedAddresses()
    var
        PurchSetup: Record "Purchases & Payables Setup";
    begin
        PurchSetup.Get;
        PurchSetup."Ignore Updated Addresses" := false;
        PurchSetup.Modify;
    end;

    procedure LookUpGenProdPostingGroup(): Code[20]
    var
        GeneralPostingSetup: Record "General Posting Setup";
        LibraryERM: Codeunit "PTK Library - ERM 4PS";
    begin
        GeneralPostingSetup.Reset();
        GeneralPostingSetup.SetFilter("Gen. Prod. Posting Group", '<>%1', '');
        GeneralPostingSetup.SetFilter("Purch. Account", '<>%1', '');
        if GeneralPostingSetup.FindFirst then
            exit(GeneralPostingSetup."Gen. Prod. Posting Group")
        else begin
            LibraryERM.FindGeneralPostingSetupInvtFull(GeneralPostingSetup);
            exit(GeneralPostingSetup."Gen. Prod. Posting Group");
        end;
    end;

    procedure PreviewPostPurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        PurchPostYesNo: Codeunit "Purch.-Post (Yes/No)";
    begin
        PurchPostYesNo.Preview(PurchaseHeader);
    end;

    procedure GetRandomVendor(var Vendor: record Vendor)
    begin
        if Vendor.Next(SessionId MOD Vendor.Count()) <> 0 then;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20]; Quantity: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateVendor(var Vendor: Record Vendor)
    begin
    end;
}

