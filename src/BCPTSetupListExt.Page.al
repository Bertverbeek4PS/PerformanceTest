pageextension 82000 BCPTSetupListExt extends "BCPT Setup List"
{
    actions
    {
        addafter(ExportBCPT)
        {
            Action(ImportAnalysesSheet)
            {
                Caption = 'Import Analyses Sheet';
                Image = ImportExcel;
                Promoted = true;
                PromotedCategory = Category4;
                PromotedIsBig = false;
                PromotedOnly = true;
                Scope = Repeater;
                ToolTip = 'Imports an Analyses Sheet.';

                trigger OnAction()
                var
                    ExcelBuffer: Record "Excel Buffer" temporary;
                    Inst: InStream;
                    FileName: Text;
                    LastRow: Integer;
                    row: Integer;
                    i: integer;
                    BCPTTestSuite: Codeunit "BCPT Test Suite";
                    BCPTCode: Label '%1Load', Locked = true;
                    BCPTDescription: Label '%1 Load test', Locked = true;
                    BCPTHeaderCode: Array[3] of text;
                    DelayType: Enum "BCPT Line Delay Type";
                    Companies: List of [Text];
                    Company: Record Company;
                begin
                    if UploadIntoStream('Analyse Sheet', '', '', FileName, Inst) then begin
                        ExcelBuffer.OpenBookStream(Inst, 'Analyses');
                        ExcelBuffer.ReadSheet();
                        //Find Last Row No
                        ExcelBuffer.SetRange("Column No.", 2);
                        ExcelBuffer.FindLast();
                        LastRow := ExcelBuffer."Row No.";
                        ExcelBuffer.Reset();
                        //Check if currentcompany is in the list
                        for row := 2 to LastRow do begin
                            if Company.Get(GetText(ExcelBuffer, 5, Row)) then
                                Companies.Add(GetText(ExcelBuffer, 5, Row));
                        end;

                        if not Companies.Contains(rec.CurrentCompany()) then
                            exit;

                        for row := 2 to LastRow do begin
                            if GetText(ExcelBuffer, 2, Row) = 'Codeunit ID' then begin
                                BCPTTestSuite.CreateTestSuiteHeader(
                                    StrSubstNo(BCPTCode, GetText(ExcelBuffer, 7, row)),
                                    StrSubstNo(BCPTDescription, GetText(ExcelBuffer, 7, row)),
                                    GetInteger(ExcelBuffer, 6, row + 1),
                                    0,
                                    0,
                                    0,
                                    '');
                                BCPTHeaderCode[1] := StrSubstNo(BCPTCode, GetText(ExcelBuffer, 7, row));
                                BCPTTestSuite.CreateTestSuiteHeader(
                                    StrSubstNo(BCPTCode, GetText(ExcelBuffer, 8, row)),
                                    StrSubstNo(BCPTDescription, GetText(ExcelBuffer, 8, row)),
                                    GetInteger(ExcelBuffer, 6, row + 1),
                                    0,
                                    0,
                                    0,
                                    '');
                                BCPTHeaderCode[2] := StrSubstNo(BCPTCode, GetText(ExcelBuffer, 8, row));
                                BCPTTestSuite.CreateTestSuiteHeader(
                                    StrSubstNo(BCPTCode, GetText(ExcelBuffer, 9, row)),
                                    StrSubstNo(BCPTDescription, GetText(ExcelBuffer, 9, row)),
                                    GetInteger(ExcelBuffer, 6, row + 1),
                                    0,
                                    0,
                                    0,
                                    '');
                                BCPTHeaderCode[3] := StrSubstNo(BCPTCode, GetText(ExcelBuffer, 9, row));
                            end else begin
                                if GetText(ExcelBuffer, 5, Row) = rec.CurrentCompany() then begin
                                    BCPTTestSuite.AddLineToTestSuiteHeader(
                                        BCPTHeaderCode[1],
                                        GetInteger(ExcelBuffer, 2, Row),
                                        GetInteger(ExcelBuffer, 7, Row),
                                        GetText(ExcelBuffer, 3, Row),
                                        0,
                                        0,
                                        GetInteger(ExcelBuffer, 12, Row),
                                        true,
                                        GetText(ExcelBuffer, 4, Row),
                                        GetDelayType(ExcelBuffer, 13, Row)
                                    );
                                    BCPTTestSuite.AddLineToTestSuiteHeader(
                                        BCPTHeaderCode[2],
                                        GetInteger(ExcelBuffer, 2, Row),
                                        GetInteger(ExcelBuffer, 8, Row),
                                        GetText(ExcelBuffer, 3, Row),
                                        0,
                                        0,
                                        GetInteger(ExcelBuffer, 12, Row),
                                        true,
                                        GetText(ExcelBuffer, 4, Row),
                                        GetDelayType(ExcelBuffer, 13, Row)
                                    );
                                    BCPTTestSuite.AddLineToTestSuiteHeader(
                                        BCPTHeaderCode[3],
                                        GetInteger(ExcelBuffer, 2, Row),
                                        GetInteger(ExcelBuffer, 9, Row),
                                        GetText(ExcelBuffer, 3, Row),
                                        0,
                                        0,
                                        GetInteger(ExcelBuffer, 12, Row),
                                        true,
                                        GetText(ExcelBuffer, 4, Row),
                                        GetDelayType(ExcelBuffer, 13, Row)
                                    );
                                end;
                            end;
                        end;
                    end;
                end;
            }
        }
    }

    procedure GetText(var ExcelBuffer: Record "Excel Buffer" temporary; Col: Integer; Row: Integer): Text
    begin
        if ExcelBuffer.Get(Row, Col) then
            Exit(ExcelBuffer."Cell Value as Text");
    end;

    procedure GetInteger(var ExcelBuffer: Record "Excel Buffer" temporary; Col: Integer; Row: Integer): Integer
    var
        Int: Integer;
    begin
        if ExcelBuffer.Get(Row, Col) then begin
            Evaluate(Int, ExcelBuffer."Cell Value as Text");
            exit(Int);
        end;
    end;

    procedure GetDelayType(var ExcelBuffer: Record "Excel Buffer" temporary; Col: Integer; Row: Integer): Enum "BCPT Line Delay Type"
    begin
        if ExcelBuffer.Get(Row, Col) then begin
            If ExcelBuffer."Cell Value as Text" = 'Fixed' then
                Exit("BCPT Line Delay Type"::Fixed);
            If ExcelBuffer."Cell Value as Text" = 'Random' then
                Exit("BCPT Line Delay Type"::Random);
        end;

    end;
}