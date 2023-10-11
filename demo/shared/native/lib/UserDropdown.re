/* module Css = UserProfileDropdown_Css;
   module GetWorkspaces = AsGetWorkspacesInterface_t;
   module GetAppearance = TkGetAppearanceInterface_t;
   module Appearance = Profile.Appearance;

   module Api = {
     let getWorkspaces = () =>
       ClientDriver.perform(AsGetWorkspacesRequest.request, ());
     let getAppearance = () =>
       ClientDriver.perform(TkGetAppearanceRequest.request, ());
     let updateAppearance = body =>
       ClientDriver.perform(TkUpdateAppearanceRequest.request, body);
     let loginGetSamlMandatorySsoRedirect = body =>
       ClientDriver.perform(
         LoginGetSamlMandatorySsoRedirectRequest.request,
         body,
       );

     type workspacesRequest =
       ClientDriver.plainValueEndpoint(GetWorkspaces.output);
     type appearanceRequest =
       ClientDriver.plainValueEndpoint(GetAppearance.data);
     type loginGetSamlMandatorySsoRedirect =
       ClientDriver.plainValueEndpoint(
         LoginGetSamlMandatorySsoRedirectInterface_t.output,
       );
   };

   type modal =
     | NoModal
     | LoginModal(GetWorkspaces.workspace);

   type state = {
     isOpen: bool,
     isAppearanceModalOpen: bool,
     workspacesRequest: Api.workspacesRequest,
     appearanceRequest: Api.appearanceRequest,
     modal,
   };

   type action =
     | SetIsOpen(bool)
     | DropdownClosed
     | WorkspacesReceived(Api.workspacesRequest)
     | AppearanceReceived(Api.appearanceRequest)
     | AppearanceMenuItemClicked
     | AppearanceModalClosed
     | AppearanceUpdated(Appearance.t)
     | ModalOpened(modal)
     | ModalClosed;

   let defaultAppearance = Appearance.Light;

   let reducer = (state, action) =>
     switch (action) {
     | SetIsOpen(isOpen) => {...state, isOpen}
     | DropdownClosed => {...state, isOpen: false}
     | WorkspacesReceived(workspacesRequest) => {...state, workspacesRequest}
     | AppearanceReceived(appearanceRequest) => {...state, appearanceRequest}
     | AppearanceMenuItemClicked => {...state, isAppearanceModalOpen: true}
     | AppearanceModalClosed => {...state, isAppearanceModalOpen: false}
     | AppearanceUpdated(appearance) => {
         ...state,
         appearanceRequest: Success(appearance),
         isAppearanceModalOpen: false,
       }
     | ModalOpened(modal) => {...state, modal}
     | ModalClosed => {...state, modal: NoModal}
     };

   let appearanceToShortLabel =
     fun
     | Appearance.Light => [%intl.s {js|Light|js}]
     | Dark => [%intl.s {js|Dark|js}]
     | System => [%intl.s {js|System|js}];

   let appearanceToFullLabel =
     fun
     | Appearance.Light => [%intl.s {js|Light|js}]
     | Dark => [%intl.s {js|Dark|js}]
     | System => [%intl.s {js|Use system settings|js}];

   let appearanceStylesheetId = "appearance-stylesheet";
   let updateStylesheet = appearance => {
     open Webapi.Dom;
     let stylesheetName =
       switch (appearance) {
       | Appearance.Light => "light"
       | Dark => "dark"
       | System => "system"
       };

     switch (Document.getElementById(appearanceStylesheetId, document)) {
     | None => ()
     | Some(stylesheetEl) =>
       let version =
         Element.getAttribute("data-version", stylesheetEl)
         ->Option.getWithDefault("");
       Element.setAttribute(
         "href",
         Printf.sprintf("/assets/css/%s-palette.css%s", stylesheetName, version),
         stylesheetEl,
       );
     };
   };

   let renderOptionToggle = (onClick, controlRef, children) =>
     <UnpaddedButton color=`darkMuted onClick domRef=controlRef>
       <Text>
         <span
           className={Cn.make([Css.workspaceName, "updateable__workspace-name"])}>
           children
         </span>
       </Text>
       <span className=Css.toggleIcon>
         <IconSet.Triangle.Neutral size=Xxs />
       </span>
     </UnpaddedButton>;

   module UserProfileDropdownItemCurrent = {
     [@react.component]
     let make = (~children) => {
       <div className=Css.userProfileDropdownItem>
         <Box padding=`control>
           <Row gap=`px10 align=`top layout=[`px(14), `fr(1.)]>
             <Text> <IconSet.Check /> </Text>
             <div className=Css.content>
               children
               <div className=Css.inviteButton>
                 <Button href=AhrefsUrls.AS.members color=`accent>
                   [%intl.el {js|Invite members|js}]
                 </Button>
               </div>
             </div>
           </Row>
         </Box>
       </div>;
     };
   };

   module UserProfileDropdownItem = {
     [@react.component]
     let make = (~href=?, ~onClick=?, ~onClose, ~children) => {
       <a
         className={Cn.make([
           Css.userProfileDropdownItem,
           Css.userProfileDropdownItemHover,
         ])}
         ?href
         onClick={e => {
           onClose();
           onClick->Option.mapWithDefault(
             (),
             onClick => {
               e->ReactEvent.Mouse.preventDefault;
               onClick();
             },
           );
         }}>
         <DropdownItem>
           <Row gap=`px10 align=`top layout=[`px(14), `fr(1.)]>
             <div />
             <div className=Css.content> children </div>
           </Row>
         </DropdownItem>
       </a>;
     };
   };

   module AppearanceModal = {
     [@react.component]
     let make = (~isOpen, ~initialAppearance, ~onSave, ~onClose) => {
       let (selectedAppearance, selectAppearance) =
         RR.useStateValue(initialAppearance);
       let (isLoading, setIsLoading) = RR.useStateValue(false);

       let updateAppearance = () => {
         setIsLoading(true);
         Api.updateAppearance(selectedAppearance)
         ->Promise.forEach(res => {
             switch (res) {
             | NotAsked
             | InitialLoading
             | Loading(_) => ()
             | Failure(_) =>
               setIsLoading(false);
               Notify.genericError();
             | Success(_) =>
               setIsLoading(false);
               updateStylesheet(selectedAppearance);
               onSave(selectedAppearance);
             }
           });
       };

       <Modal isOpen onClose>
         <Modal.Header> [%intl.el {js|Appearance|js}] </Modal.Header>
         <Modal.Body>
           <RadioGroup layout=`vertical>
             {[Appearance.Light, Dark, System]
              ->List.map(appearance => {
                  let label = appearance->appearanceToFullLabel;
                  <Radio
                    key=label
                    name="appearance"
                    label={label->RR.s}
                    checked={selectedAppearance == appearance}
                    onChange={_ => selectAppearance(appearance)}
                  />;
                })
              ->RR.list}
           </RadioGroup>
         </Modal.Body>
         <Modal.Footer>
           <InlineRow gap=`px10>
             <Button
               color=`accent loading=isLoading onClick={_ => updateAppearance()}>
               [%intl.el {js|Save|js}]
             </Button>
             <Button color=`outline onClick={_ => onClose()}>
               [%intl.el {js|Cancel|js}]
             </Button>
           </InlineRow>
         </Modal.Footer>
       </Modal>;
     };
   };

   let renderWorkspace =
       (
         {name, numMembers, productName, id}: GetWorkspaces.workspace,
         ~isCurrent=false,
         ~onClose=_ => (),
         ~onClick=?,
         (),
       ) => {
     let planNameAndMemberStr = {
       Printf.sprintf(
         "%s %s, %s",
         productName->PricingT.ProductName.toString->Intl.format,
         [%intl.s {msg: {js|plan|js}, desc: "subscription plan"}],
         [%intl.s
           {
             msg: {js|{numMembers} {numMembersCount, plural, zero {members} one {member} few {members} other {members}}|js},
             desc: "1 member, 2 members, 3 members etc",
           }
         ] @@
         {"numMembers": numMembers->Int.toString, "numMembersCount": numMembers},
       );
     };
     let children =
       <>
         <Text fontWeight=`bold truncate=true title=name>
           <span className={"updateable__workspace-name"->Cn.ifTrue(isCurrent)}>
             name->RR.s
           </span>
         </Text>
         <Text
           fontSize=`sm color=`secondary truncate=true title=planNameAndMemberStr>
           planNameAndMemberStr->RR.s
         </Text>
       </>;
     isCurrent
       ? <UserProfileDropdownItemCurrent key={EsMapping.CompanyId.show(id)}>
           children
         </UserProfileDropdownItemCurrent>
       : <UserProfileDropdownItem
           key={EsMapping.CompanyId.show(id)} ?onClick onClose>
           children
         </UserProfileDropdownItem>;
   };

   [@react.component]
   let make = () => {
     let (state, dispatch) =
       React.useReducer(
         reducer,
         {
           isOpen: false,
           isAppearanceModalOpen: false,
           appearanceRequest: NotAsked,
           workspacesRequest: NotAsked,
           modal: NoModal,
         },
       );

     let controlRef = React.useRef(Js.Nullable.null);

     React.useEffect0(() => {
       Api.getWorkspaces()
       ->Promise.forEach(res => dispatch @@ WorkspacesReceived(res));
       Api.getAppearance()
       ->Promise.forEach(res => dispatch @@ AppearanceReceived(res));
       None;
     });

     let currentWorkspace =
       switch (state.workspacesRequest) {
       | Success({workspaces: [head]})
       | Success({workspaces: [head, ..._]}) => Some(head)
       | _ => None
       };

     let currentWorkspaceName =
       currentWorkspace->Option.mapWithDefault("", ({name, _}) => name);

     let onClose = () => dispatch @@ DropdownClosed;

     let loginGetSamlMandatorySsoRedirect = companyId =>
       Api.loginGetSamlMandatorySsoRedirect({company_id: Some(companyId)})
       ->Promise.forEach(res =>
           switch (res) {
           | NotAsked
           | InitialLoading
           | Loading(_) => ()
           | Failure(_)
           | Success(`SamlSsoUnavailable)
           | Success(`Ok({id: _, payload: _, binding: `HTTP_POST(_)})) =>
             Notify.error(
               [%intl_draft.s {js|Failed to redirect to SSO login URL.|js}],
             )
           | Success(`Ok({id: _, payload: _, binding: `HTTP_REDIRECT(url)})) =>
             Location.setHref(Wrap.Url.show(url))
           }
         );

     <>
       <Modal
         isOpen={state.modal != NoModal}
         onClose={_ => dispatch @@ ModalClosed}
         maxWidth={`px(372)}>
         {switch (state.modal) {
          | NoModal => RR.null
          | LoginModal(workspace) =>
            <UserLoginForm
              title={
                [%intl.s {js|Sign in to access {workspace}|js}] @@
                {"workspace": workspace.name}
              }
              showSso=false
              activeCompanyId={workspace.id}
            />
          }}
       </Modal>
       <Row>
         {switch (currentWorkspace) {
          | Some({productName, _})
              when productName->PricingT.ProductName.isPromoted =>
            FeatureFlag.showNewUserReportLevelComponent
              ? <UserReportLevelNew /> : <UserReportLevel />
          | Some(_)
          | None => RR.null
          }}
         <Deprecated__DropdownBase
           menuRight=true
           menuWidth={Custom(230)}
           deprecated_customControl={
             Focusable(
               controlRef,
               (~disabled as _, ~onMouseDown, children) =>
                 onMouseDown->renderOptionToggle(controlRef, children),
             )
           }
           deprecated_customControlLabel={_ => currentWorkspaceName->RR.s}
           isOpen={state.isOpen}
           dispatch={action =>
             dispatch @@
             SetIsOpen(
               Deprecated__DropdownBase.defaultReducer(state.isOpen, action),
             )
           }>
           <div className=Css.menu>
             {switch (state.workspacesRequest) {
              | Success({workspaces}) =>
                switch (workspaces) {
                | [] => RR.null
                | [head] => head->renderWorkspace(~isCurrent=true, ())
                | [head, ...tail] =>
                  <>
                    {head->renderWorkspace(~isCurrent=true, ())}
                    {tail
                     ->List.map(workspace =>
                         workspace->renderWorkspace(
                           ~onClick=
                             _ =>
                               ClientDriver.perform(
                                 ~onUnauthorized=
                                   () =>
                                     dispatch @@
                                     ModalOpened(LoginModal(workspace)),
                                 AsSwitchWorkspaceRequest.request,
                                 {workspaceId: workspace.id},
                               )
                               ->Promise.forEach(res =>
                                   switch (res) {
                                   | NotAsked
                                   | InitialLoading
                                   | Loading(_) => ()
                                   | Success(_) => Location.setHref("/")
                                   | Failure({error: `Company_requires_SSO, _}) =>
                                     loginGetSamlMandatorySsoRedirect(
                                       workspace.id,
                                     )
                                   | Failure({error: `Unauthorized, _}) => ()
                                   | Failure(_) =>
                                     Notify.error(
                                       [%intl.s
                                         {js|Failed to switch workspace.|js}
                                       ],
                                     )
                                   }
                                 ),
                           ~onClose,
                           (),
                         )
                       )
                     ->RR.list}
                  </>
                }
              | _ => RR.null
              }}
             <UserProfileDropdownItem onClose href=AhrefsUrls.AS.account>
               [%intl.el {js|Account settings|js}]
             </UserProfileDropdownItem>
             <UserProfileDropdownItem
               onClose onClick={_ => dispatch @@ AppearanceMenuItemClicked}>
               <Row layout=[`fr(1.), `auto]>
                 <InlineRow gap=`px4>
                   [%intl.el {js|Appearance|js}]
                   <NewLabel color=`muted> [%intl.el {js|Beta|js}] </NewLabel>
                 </InlineRow>
                 {switch (state.appearanceRequest) {
                  | NotAsked => RR.null
                  | InitialLoading
                  | Loading(_) => <Loader.Icon />
                  | Failure(_) =>
                    /* No recovery, ignoring */
                    RR.null
                  | Success(appearance) =>
                    <Text color=`secondary fontSize=`xs>
                      {appearance->appearanceToShortLabel->RR.s}
                    </Text>
                  }}
               </Row>
             </UserProfileDropdownItem>
             <UserProfileDropdownItem
               href=AhrefsUrls.Auth.logout
               onClose
               onClick={_ => {
                 Intercom.shutdown();
                 AuthT.logoutUser()->Promise.forEach(_ => Location.reloadPage());
               }}>
               [%intl.el {js|Sign out|js}]
             </UserProfileDropdownItem>
           </div>
         </Deprecated__DropdownBase>
         {switch (state.appearanceRequest) {
          | NotAsked
          | InitialLoading
          | Loading(_)
          | Failure(_) => RR.null
          | Success(appearance) =>
            <AppearanceModal
              isOpen={state.isAppearanceModalOpen}
              initialAppearance=appearance
              onClose={() => dispatch @@ AppearanceModalClosed}
              onSave={appearance => dispatch @@ AppearanceUpdated(appearance)}
            />
          }}
       </Row>
     </>;
   };
    */
