codeunit 80511 "Library - Graph Mgt"
{

    trigger OnRun()
    begin
    end;

    var
        HttpWebRequest: HttpRequestMessage;
        HttpContentHeaders: HttpHeaders;
        Content: HttpContent;
        Client: HttpClient;
        OdataType: option API,WS;

    procedure RequestMessage(UserName: Text; Password: Text; Uri: Text; Method: Option Get,Post,Patch; Body: Text): JsonObject
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        JsonResponse: JsonObject;
        AccessToken: Text;
        JsonContent: Text;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        RequestMessage.Method(format(Method));
        RequestMessage.SetRequestUri(Uri);

        if Method <> Method::Get then begin
            Content.WriteFrom(body);
            Content.GetHeaders(ContentHeaders);
            ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            RequestMessage.Content(Content);
        end;

        AddHttpBasicAuthHeader(Username, Password, Client);
        Client.DefaultRequestHeaders().Add('Accept', 'application/json');
        if Method = Method::Patch then
            Client.DefaultRequestHeaders().Add('If-Match', '*');


        if Client.Send(RequestMessage, ResponseMessage) then begin
            if (ResponseMessage.HttpStatusCode = 200) or (ResponseMessage.HttpStatusCode = 201) then begin
                ResponseMessage.Content.ReadAs(JsonContent);
                JsonResponse.ReadFrom(JsonContent);
                exit(JsonResponse);
            end;
        end;
    end;

    local procedure AddHttpBasicAuthHeader(UserName: Text; Password: Text; var HttpClient: HttpClient);
    var
        AuthString: Text;
        Base64Convert: codeunit "Base64 Convert";
    begin
        AuthString := STRSUBSTNO('%1:%2', UserName, Password);
        AuthString := Base64Convert.ToBase64(AuthString);
        AuthString := STRSUBSTNO('Basic %1', AuthString);
        HttpClient.DefaultRequestHeaders().Add('Authorization', AuthString);
    end;

    procedure CreateTargetURL(ID: Text; PageNumber: Integer; ServiceNameTxt: Text): Text
    var
        TargetURL: Text;
        ReplaceWith: Text;
    begin
        TargetURL := GetODataTargetURL(ObjectType::Page, PageNumber);
        if ID <> '' then begin
            ReplaceWith := StrSubstNo('%1(%2)', ServiceNameTxt, StripBrackets(ID));
            TargetURL := STRREPLACE(TargetURL, ServiceNameTxt, ReplaceWith);
        end;
        exit(TargetURL);
    end;

    procedure GetODataTargetURL(ObjType: ObjectType; ObjectNumber: Integer): Text
    var
        ApiWebService: Record "Api Web Service";
        WebServiceAggregate: Record "Web Service Aggregate";
        WebServiceManagement: Codeunit "Web Service Management";
        WebServiceClientType: Enum "Client Type";
        ApiWebServiceObjectType: Option;
        WebServiceAggregateObjectType: Option;
        OdataUrl: Text;
    begin
        if ObjType = OBJECTTYPE::Page then begin
            ApiWebServiceObjectType := ApiWebService."Object Type"::Page;
            WebServiceAggregateObjectType := WebServiceAggregate."Object Type"::Page;
        end else begin
            ApiWebServiceObjectType := ApiWebService."Object Type"::Query;
            WebServiceAggregateObjectType := WebServiceAggregate."Object Type"::Query;
        end;

        ApiWebService.SetRange(Published, true);
        ApiWebService.SetRange("Object ID", ObjectNumber);
        ApiWebService.SetRange("Object Type", ApiWebServiceObjectType);
        if ApiWebService.FindFirst then begin
            OdataType := OdataType::API;
            OdataUrl := GetUrl(CLIENTTYPE::Api, CompanyName, ObjType, ObjectNumber);
            exit(OdataUrl);
        end;
        WebServiceManagement.LoadRecords(WebServiceAggregate);
        WebServiceAggregate.SetRange(Published, true);
        WebServiceAggregate.SetRange("Object ID", ObjectNumber);
        WebServiceAggregate.SetRange("Object Type", WebServiceAggregateObjectType);
        WebServiceAggregate.FindFirst;
        OdataType := OdataType::WS;
        OdataUrl := WebServiceManagement.GetWebServiceUrl(WebServiceAggregate, WebServiceClientType::ODataV4);
        exit(OdataUrl);
    end;

    procedure STRREPLACE(String: Text; ReplaceWhat: Text; ReplaceWith: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrPos(String, ReplaceWhat);
        if Pos > 0 then
            String := DelStr(String, Pos) + ReplaceWith + CopyStr(String, Pos + StrLen(ReplaceWhat));
        exit(String);
    end;

    procedure StripBrackets(StringWithBrackets: Text): Text
    begin
        if StrPos(StringWithBrackets, '{') = 1 then begin
            StringWithBrackets := CopyStr(Format(StringWithBrackets), 2, 36);
            if OdataType = OdataType::WS then
                exit(StrSubstNo('''' + StringWithBrackets + ''''))
            else
                exit(StringWithBrackets);
        end;
        //exit(CopyStr(Format(StringWithBrackets), 2, 36));
        //exit(StringWithBrackets);
        if OdataType = OdataType::WS then
            exit(StrSubstNo('''' + StringWithBrackets + ''''))
        else
            exit(StringWithBrackets);
    end;

    procedure GetAccessToken(): Text
    var
        OAuth2: Codeunit OAuth2;
        AccessToken: Text;
        AuthCodeError: Text;
        Scopes: List of [Text];
    begin
        Scopes.Add('https://api.businesscentral.dynamics.com/.default');
        OAuth2.AcquireTokenWithClientCredentials(
            'AppId',
            'SecretID',
            'https://login.microsoftonline.com/f347666b-e7a9-4dbb-a45f-7836c70d3024/oauth2/v2.0/token',
            'https://businesscentral.dynamics.com/OAuthLanding.htm',
            Scopes,
            AccessToken);

        if (AccessToken = '') or (AuthCodeError <> '') then
            Error(AuthCodeError);

        exit(AccessToken);
    end;

    procedure RequestMessage(Uri: Text; Method: Option Get,Post,Patch; Body: Text): JsonObject
    var
        Client: HttpClient;
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        JsonResponse: JsonObject;
        AccessToken: Text;
        JsonContent: Text;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
    begin
        AccessToken := GetAccessToken();

        RequestMessage.Method(format(Method));
        RequestMessage.SetRequestUri(Uri);

        if Method = Method::Post then begin
            Content.WriteFrom(body);
            Content.GetHeaders(ContentHeaders);
            ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            RequestMessage.Content(Content);
        end;

        Client.DefaultRequestHeaders().Add('Authorization', StrSubstNo('Bearer %1', AccessToken));
        Client.DefaultRequestHeaders().Add('Accept', 'application/json');

        if Client.Send(RequestMessage, ResponseMessage) then begin
            if ResponseMessage.HttpStatusCode = 200 then begin
                ResponseMessage.Content.ReadAs(JsonContent);
                JsonResponse.ReadFrom(JsonContent);
                exit(JsonResponse);
            end;
        end;
    end;
}