<%
/* =================================================================
 * 작성일 : 2018.04
 * 작성자 : 이동현
 * 상세설명 : 디렉터 인증서 관리 화면
 * =================================================================
 */ 
%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="sec" uri="http://www.springframework.org/security/tags"%>
<%@ taglib prefix="spring" uri = "http://www.springframework.org/tags" %>
<script>
var text_required_msg = '<spring:message code="common.text.vaildate.required.message"/>';//을(를) 입력하세요.
var text_injection_msg='<spring:message code="common.text.validate.sqlInjection.message"/>';//입력하신 값은 입력하실 수 없습니다.
var text_ip_msg = '<spring:message code="common.text.validate.ip.message"/>';
var credentailLayout = {
        layout2: {
            name: 'layout2',
            padding: 4,
            panels: [
                { type: 'left', size: '65%', resizable: true, minSize: 300 },
                { type: 'main', minSize: 300 }
            ]
        },
        /********************************************************
         *  설명 : 디렉터 인증서 Grid
        *********************************************************/
        grid: {
            name: 'credential_GroupGrid',
            header: '<b>디렉터 인증서</b>',
            method: 'GET',
                multiSelect: false,
            show: {
                    selectColumn: true,
                    footer: true},
            style: 'text-align: center',
            columns:[
                   { field: 'recid', hidden: true },
                   { field: 'credentialName', caption: '디렉터 인증서 명', size:'25%', style:'text-align:center;' },
                   { field: 'credentialKeyName', caption: '디렉터 인증서 파일 명', size:'50%', style:'text-align:center;' },
                   { field: 'directorPublicIp', caption: 'BOOTSTRAP 공인 IP', size:'50%', style:'text-align:center;'},
                   { field: 'directorPrivateIp', caption: 'BOOTSTRAP 내부 IP', size:'50%', style:'text-align:center;'},
                  ],
            onSelect : function(event) {
                event.onComplete = function() {
                    $('#deleteBtn').attr('disabled', false);
                    return;
                }
            },
            onUnselect : function(event) {
                event.onComplete = function() {
                    $('#deleteBtn').attr('disabled', true);
                    return;
                }
            },onLoad:function(event){
                if(event.xhr.status == 403){
                    location.href = "/abuse";
                    event.preventDefault();
                }
            },onError : function(event) {
            },
        form: { 
            header: 'Edit Record',
            name: 'regPopupDiv',
            fields: [
                { name: 'recid', type: 'text', html: { caption: 'ID', attr: 'size="10" readonly' } },
                { name: 'fname', type: 'text', required: true, html: { caption: 'First Name', attr: 'size="40" maxlength="40"' } },
                { name: 'lname', type: 'text', required: true, html: { caption: 'Last Name', attr: 'size="40" maxlength="40"' } },
                { name: 'email', type: 'email', html: { caption: 'Email', attr: 'size="30"' } },
                { name: 'sdate', type: 'date', html: { caption: 'Date', attr: 'size="10"' } }
            ],
            actions: {
                Reset: function () {
                    this.clear();
                },
                Save: function () {
                    var errors = this.validate();
                    if (errors.length > 0) return;
                    if (this.recid == 0) {
                        w2ui.grid.add($.extend(true, { recid: w2ui.grid.records.length + 1 }, this.record));
                        w2ui.grid.selectNone();
                        this.clear();
                    } else {
                        w2ui.grid.set(this.recid, this.record);
                        w2ui.grid.selectNone();
                        this.clear();
                    }
                }
            }
        }
    }
}

$(function(){
    doSearch();
    $("#addBtn").click(function(){
        w2popup.open({
            title     : "<b>디렉터 인증서 등록</b>",
            width     : 600,
            height    : 280,
            modal    : true,
            body    : $("#regPopupDiv").html(),
            buttons : $("#regPopupBtnDiv").html(),
            onClose : function(event){
                w2ui['credential_GroupGrid'].clear();
                doSearch();
            }
        });
    });
    
    $("#deleteBtn").click(function(){
        if($("#deleteBtn").attr('disabled') == "disabled") return;
        var selected = w2ui['credential_GroupGrid'].getSelection();
        if( selected.length == 0 ){
            w2alert("선택된 정보가 없습니다.", "디렉터 인증서 삭제");
            return;
        }
        else {
            var record = w2ui['credential_GroupGrid'].get(selected);
            w2confirm({
                title        : "디렉터 인증서",
                msg            : "디렉터 인증서("+record.credentialName + ")을 삭제하시겠습니까?",
                yes_text    : "확인",
                no_text        : "취소",
                yes_callBack: function(event){
                    deleteDirectorCredencialInfo(record.recid, record.credentialName);
                },
                no_callBack    : function(){
                    w2ui['credential_GroupGrid'].clear();
                    doSearch();
                }
            });
        }
    });
});

/********************************************************
 * 설명 : 인증서 목록 조회
 * 기능 : doSearch
 *********************************************************/
function doSearch() {
    $('#credential_GroupGrid').w2layout(credentailLayout.layout2);
    w2ui.layout2.content('left', $().w2grid(credentailLayout.grid));
    w2ui['layout2'].content('main', $('#regPopupDiv').html());
    w2ui['credential_GroupGrid'].load('/config/credentail/list');
    doButtonStyle(); 
}

/********************************************************
 * 설명 : 초기 버튼 스타일
 * 기능 : doButtonStyle
 *********************************************************/
function doButtonStyle() {
    $('#deleteBtn').attr('disabled', true);
}

/********************************************************
 * 설명 : 디렉터 인증서 정보 등록
 * 기능 : registDirectorCredentialInfo
 *********************************************************/
function registDirectorCredentialInfo(){
    w2popup.lock("등록 중입니다.", true);
    var credentialInfo = {
        credentialName : $(".w2ui-msg-body input[name='credentialName']").val(),    
        directorPublicIp : $(".w2ui-msg-body input[name='directorPublicIp']").val(),
        directorPrivateIp : $(".w2ui-msg-body input[name='directorPrivateIp']").val()
    }
    $.ajax({
        type : "POST",
        url : "/config/credentail/save",
        contentType : "application/json",
        async : true,
        data : JSON.stringify(credentialInfo),
        success : function(status) {
            w2popup.unlock();
            w2popup.close();
            doSearch();
        }, error : function(request, status, error) {
            w2popup.unlock();
            w2popup.close();
            var errorResult = JSON.parse(request.responseText);
            w2alert(errorResult.message);
        }
    });
}

/********************************************************
 * 설명 : 디렉터 인증서 정보 삭제
 * 기능 : deleteDirectorCredencialInfo
 *********************************************************/
function deleteDirectorCredencialInfo(id, credentialName){
    w2popup.lock("삭제 중입니다.", true);
    var credentialInfo = {
        id : id,    
        credentialName : credentialName,
    }
    $.ajax({
        type : "DELETE",
        url : "/config/credentail/delete",
        contentType : "application/json",
        async : true,
        data : JSON.stringify(credentialInfo),
        success : function(status) {
            w2popup.unlock();
            w2popup.close();
            doSearch();
        }, error : function(request, status, error) {
            w2popup.unlock();
            w2popup.close();
            var errorResult = JSON.parse(request.responseText);
            w2alert(errorResult.message);
        }
    });
}

/********************************************************
 * 설명 : 화면 리사이즈시 호출
 *********************************************************/
$( window ).resize(function() {
    setLayoutContainerHeight();
});

/********************************************************
 * 설명 : Lock 팝업 메세지 Function
 * 기능 : lock
 *********************************************************/
function lock (msg) {
    w2popup.lock(msg, true);
}
/********************************************************
 * 설명 : 다른 페이지 이동 시 호출 Function
 * 기능 : clearMainPage
 *********************************************************/
function clearMainPage() {
    $().w2destroy('layout2');
    $().w2destroy('credential_GroupGrid');
}


</script>
<div id="main">
    <div class="page_site">플랫폼 설치 자동화 관리 > <strong>디렉터 인증서 관리</strong></div>
    <!-- 사용자 목록-->
    <div class="pdt20">
        <div class="title fl">디렉터 인증서 관리</div>
<%--         <div class="fr"> 
            <sec:authorize access="hasAuthority('ADMIN_USER_MENU')">
                <span id="addBtn" class="btn btn-primary" style="width:120px">등록</span>
                <span id="deleteBtn" class="btn btn-danger" style="width:120px">삭제</span>
            </sec:authorize>
        </div> --%>
    </div>
    <div id="credential_GroupGrid" style="width:100%;  height:650px;"></div>
    <!-- 인증서 추가 팝업 -->
</div>
<div id="regPopupDiv" hidden="true">
    <form id="settingForm" action="POST">
        <div class="w2ui-page page-0" style="">
           <div class="panel panel-default">
               <div class="panel-heading"><b>디렉터 인증서 정보</b></div>
               <div class="panel-body" style="height:560px; overflow-y:auto;">
                   <div class="w2ui-field">
                       <label style="width:40%;text-align: left;padding-left: 20px;">디렉터 인증서 명</label>
                       <div>
                           <input class="form-control" name="credentialName" type="text" maxlength="100" style="width: 320px; margin-left: 20px;" placeholder="디렉터 인증서 명을 하세요."/>
                       </div>
                   </div>
                   <div class="w2ui-field">
                       <label style="width:40%;text-align: left;padding-left: 20px;">BOOTSTRAP 공인 IPs</label>
                       <div>
                           <input class="form-control" name="directorPublicIp" type="text" maxlength="100" style="width: 320px; margin-left: 20px;" placeholder="BOOTSTRAP 공인 IPs를 하세요."/>
                       </div>
                   </div>
                   <div class="w2ui-field">
                       <label style="width:40%;text-align: left;padding-left: 20px;">BOOTSTRAP 내부 IPs</label>
                       <div>
                           <input class="form-control" name="directorPrivateIp" type="text" maxlength="100" style="width: 320px; margin-left: 20px;" placeholder="BOOTSTRAP 내부 IPs를 하세요."/>
                       </div>
                   </div>
               </div>
           </div>
        </div>
    </form>
    <div id="regPopupBtnDiv" style="text-align: center; margin-top: 5px;">
        <span id="addSubnetBtn" onclick="$('#settingForm').submit();" class="btn btn-primary">등록</span>
        <span id="deleteSubnetBtn" onclick="deletexxxxxx();" class="btn btn-danger">삭제</span>
    </div>
</div>
<script>
$(function() {
    $.validator.addMethod("sqlInjection", function(value, element, params) {
        return checkInjectionBlacklist(params);
    },text_injection_msg);
    
    $.validator.addMethod( "ipv4", function( value, element, params ) {
        return /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/.test(params);
    }, "Please enter a valid IP v4 address." );

    $("#settingForm").validate({
        ignore : "",
        onfocusout: true,
        rules: {
            credentialName : {
                required : function(){
                    return checkEmpty( $(".w2ui-msg-body input[name='credentialName']").val() );
                }, sqlInjection : function(){
                    return $(".w2ui-msg-body input[name='credentialName']").val();
                }
            },
            directorPublicIp : {
                required : function(){
                    return checkEmpty( $(".w2ui-msg-body input[name='directorPublicIp']").val() );
                },  ipv4 : function(){
                    return $(".w2ui-msg-body input[name='directorPublicIp']").val();
                }
             }
        }, messages: {
            credentialName: { required:  "디렉터 인증 서 명" + text_required_msg },
            directorPublicIp: {  required:  "디렉터 공인 IPs" + text_required_msg , ipv4: text_ip_msg}
        }, unhighlight: function(element) {
            setSuccessStyle(element);
        },errorPlacement: function(error, element) {
            //do nothing
        }, invalidHandler: function(event, validator) {
            var errors = validator.numberOfInvalids();
            if (errors) {
                setInvalidHandlerStyle(errors, validator);
            }
        }, submitHandler: function (form) {
            registDirectorCredentialInfo();
        }
    });
});
</script>