page 82000 "Customer API 4PS"
{
    PageType = API;
    APIPublisher = '4ps';
    APIGroup = 'crm';
    APIVersion = 'v1.0';
    EntityName = 'customer';
    EntitySetName = 'customers';
    SourceTable = Customer;
    DelayedInsert = true;
    ODataKeyFields = SystemId;

    layout
    {
        area(Content)
        {
            repeater(GroupName)
            {
                field(no; Rec."No.") { }
                field(name; Rec.Name) { }
                field(name2; Rec."Name 2") { }
                field(address; Rec.Address) { }
                field(address2; Rec."Address 2") { }
                field(postCode; Rec."Post Code") { }
                field(city; Rec.City) { }
                field(countryRegionCode; Rec."Country/Region Code") { }
                field(phoneNo; Rec."Phone No.") { }
                field(icPartnerCode; Rec."IC Partner Code") { }
                field(eMail; Rec."E-Mail") { }
                field(contact; Rec.Contact) { }
                field(salespersonCode; Rec."Salesperson Code") { }
                field(responsibilityCenter; Rec."Responsibility Center") { }
                field(locationCode; Rec."Location Code") { }
                field(customerPostingGroup; Rec."Customer Posting Group") { }
                field(genBusPostingGroup; Rec."Gen. Bus. Posting Group") { }
                field(vatBusPostingGroup; Rec."VAT Bus. Posting Group") { }
                field(customerPriceGroup; Rec."Customer Price Group") { }
                field(customerDiscGroup; Rec."Customer Disc. Group") { }
                field(paymentTermsCode; Rec."Payment Terms Code") { }
                field(reminderTermsCode; Rec."Reminder Terms Code") { }
                field(finChargeTermsCode; Rec."Fin. Charge Terms Code") { }
                field(currencyCode; Rec."Currency Code") { }
                field(languageCode; Rec."Language Code") { }
                field(searchName; Rec."Search Name") { }
                field(creditLimitLCY; Rec."Credit Limit (LCY)") { }
                field(blocked; Rec.Blocked) { }
                field(privacyBlocked; Rec."Privacy Blocked") { }
                field(lastDateModified; Rec."Last Date Modified") { }
                field(applicationMethod; Rec."Application Method") { }
                field(combineShipments; Rec."Combine Shipments") { }
                field(reserve; Rec.Reserve) { }
                field(shipToCode; Rec."Ship-to Code") { }
                field(shippingAdvice; Rec."Shipping Advice") { }
                field(shippingAgentCode; Rec."Shipping Agent Code") { }
                field(baseCalendarCode; Rec."Base Calendar Code") { }
                field(balanceLCY; Rec."Balance (LCY)") { }
                field(balanceDueLCY; Rec."Balance Due (LCY)") { }
                field(salesLCY; Rec."Sales (LCY)") { }
                field(paymentsLCY; Rec."Payments (LCY)") { }
                field(systemId; Rec.SystemId) { }
                field(systemCreatedAt; Rec.SystemCreatedAt) { }
                field(systemCreatedBy; Rec.SystemCreatedBy) { }
                field(systemModifiedAt; Rec.SystemModifiedAt) { }
                field(systemModifiedBy; Rec.SystemModifiedBy) { }
            }
        }
    }
}