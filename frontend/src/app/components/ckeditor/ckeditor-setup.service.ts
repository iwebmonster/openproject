import {PathHelperService} from "core-app/modules/common/path-helper/path-helper.service";
import {HalResource} from "core-app/modules/hal/resources/hal-resource";
import {Injectable} from "@angular/core";

export interface ICKEditorInstance {
  getData():string;
  setData(content:string):void;
  editing:any;
  config:any;
}

export interface ICKEditorStatic {
  create(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;
  createCustomized(el:HTMLElement, config?:any):Promise<ICKEditorInstance>;
}

export interface ICKEditorContext {
  resource?:HalResource;
  // Specific removing of plugins
  removePlugins?:string[];
  // Set of enabled macro plugins or false to disable all
  macros?:false|string[];
}

declare global {
  interface Window {
    OPBalloonEditor:ICKEditorStatic;
    OPClassicEditor:ICKEditorStatic;
  }
}

@Injectable()
export class CKEditorSetupService {
 constructor(private PathHelper:PathHelperService) {
 }

  /**
   * Create a CKEditor instance of the given type on the wrapper element.
   * Pass a ICKEditorContext object that will be used to decide active plugins.
   *
   *
   * @param {"classic" | "balloon"} type
   * @param {HTMLElement} wrapper
   * @param {ICKEditorContext} context
   * @returns {Promise<ICKEditorInstance>}
   */
 public create(type:'classic'|'balloon', wrapper:HTMLElement, context:ICKEditorContext) {
   const editor = type === 'balloon' ? window.OPBalloonEditor : window.OPClassicEditor;

   return editor
     .createCustomized(wrapper, {
       openProject: {
         context: context,
         helpURL: this.PathHelper.textFormattingHelp(),
         pluginContext: window.OpenProject.pluginContext.value
       }
     })
     .catch((error:any) => {
       console.error(`Failed to setup CKEditor instance: ${error}`);
     });
 }
}
