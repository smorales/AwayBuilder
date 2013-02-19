package awaybuilder.scene.controllers
{
	import away3d.cameras.Camera3D;
	import away3d.containers.Scene3D;
	import away3d.containers.View3D;
	import away3d.core.managers.Stage3DManager;
	import away3d.core.managers.Stage3DProxy;
	import away3d.core.pick.PickingColliderType;
	import away3d.core.pick.PickingType;
	import away3d.entities.Entity;
	import away3d.entities.Mesh;
	import away3d.events.MouseEvent3D;
	import away3d.events.Stage3DEvent;
	import away3d.lights.LightBase;
	import away3d.materials.lightpickers.StaticLightPicker;
	import away3d.primitives.WireframePlane;
	
	import awaybuilder.scene.controls.Gizmo3DBase;
	import awaybuilder.scene.controls.LightGizmo3D;
	import awaybuilder.scene.controls.RotateGizmo3D;
	import awaybuilder.scene.controls.ScaleGizmo3D;
	import awaybuilder.scene.controls.TranslateGizmo3D;
	import awaybuilder.scene.events.Scene3DManagerEvent;
	import awaybuilder.scene.modes.GizmoMode;
	import awaybuilder.scene.views.OrientationTool;
	
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Vector3D;
	import flash.ui.Keyboard;
	
	import mx.collections.ArrayList;
	import mx.core.UIComponent;
	
	[Bindable]
	
	public class Scene3DManager extends EventDispatcher
	{
		// Singleton instance declaration
		public static const instance:Scene3DManager = new Scene3DManager();		
		public function Scene3DManager() { if ( instance ) throw new Error("Scene3DManager is a singleton"); }		
		
		public static var active:Boolean = true;

		public static var scope:UIComponent;
		public static var stage:Stage;
		public static var stage3DProxy:Stage3DProxy;
		public static var mode:String;
		public static var view:View3D;
		public static var scene:Scene3D;
		public static var camera:Camera3D;
		
		public static var selectedObjects:ArrayList = new ArrayList();
		public static var selectedObject:Entity;
		public static var multiSelection:Boolean = false;
		
		public static var objects:ArrayList = new ArrayList();
		public static var lights:ArrayList = new ArrayList();
		
		public static var grid:WireframePlane;
		public static var orientationTool:OrientationTool;
		
		public static var currentGizmo:Gizmo3DBase;
		public static var translateGizmo:TranslateGizmo3D;
		public static var rotateGizmo:RotateGizmo3D;
		public static var scaleGizmo:ScaleGizmo3D;
		
		private static var lightGizmos:ArrayList = new ArrayList();
		
		public static function init(scope:UIComponent):void
		{
			Scene3DManager.scope = scope;			
			Scene3DManager.stage = scope.stage;
			
			stage3DProxy = Stage3DManager.getInstance(stage).getFreeStage3DProxy();
			stage3DProxy.antiAlias = 4;
			stage3DProxy.color = 0x333333;
			stage3DProxy.addEventListener(Stage3DEvent.CONTEXT3D_CREATED, instance.onContextCreated);				
		}
		
		private function onContextCreated(e:Stage3DEvent):void 
		{
			//Create view3D, camera and add to stage
			view = new View3D();
			view.shareContext = true;
			view.stage3DProxy = stage3DProxy;	
			view.mousePicker = PickingType.RAYCAST_BEST_HIT;
			view.camera.lens.near = 1;
			view.camera.lens.far = 10000;			
			view.camera.position = new Vector3D(0, 200, -1000);
			view.camera.rotationX = 0;
			view.camera.rotationY = 0;	
			view.camera.rotationZ = 0			
			scope.addChild(view);
			Scene3DManager.scene = view.scene;
			Scene3DManager.camera = view.camera;							
			
			
			//Create Gizmos
			translateGizmo = new TranslateGizmo3D();
			scene.addChild(translateGizmo);
			rotateGizmo = new RotateGizmo3D();
			scene.addChild(rotateGizmo);
			scaleGizmo = new ScaleGizmo3D();
			scene.addChild(scaleGizmo);	
			
			//assing default gizmo
			currentGizmo = translateGizmo;
			
			
			//Create OrientationTool			
			orientationTool = new OrientationTool();
			scope.addChild(orientationTool);
			
			
			//Create Grid
			grid = new WireframePlane(10000, 10000, 100, 100, 0x000000, 1, "xz");
			grid.mouseEnabled = false;
			scene.addChild(grid);	
			
			
			//Camera Settings
			CameraManager.init(scope, view);	
			
			
			//handle stage events
			stage.addEventListener(KeyboardEvent.KEY_DOWN, instance.onKeyDown);
			stage.addEventListener(KeyboardEvent.KEY_UP, instance.onKeyUp);			
			stage.addEventListener(MouseEvent.MOUSE_DOWN, instance.onMouseDown);
			stage.addEventListener(MouseEvent.MOUSE_UP, instance.onMouseUp);
			
			scope.addEventListener(Event.RESIZE, instance.handleScreenSize);
			instance.handleScreenSize();
			
			stage3DProxy.addEventListener(Event.ENTER_FRAME, instance.loop);		
			
			dispatchEvent(new Scene3DManagerEvent(Scene3DManagerEvent.READY));
		}
		
		private function loop(e:Event):void 
		{
			orientationTool.update();
			currentGizmo.update();
			
			view.render();			
		}		
		
		private function handleScreenSize(e:Event=null):void 
		{
			orientationTool.x = scope.width - orientationTool.width - 10;
			orientationTool.y = 5;
			
			stage3DProxy.width = stage.stageWidth;
			stage3DProxy.height = stage.stageHeight;			
			
			view.width = scope.width;
			view.height = scope.height;
		}	
		
		
		
		// Mouse Events *************************************************************************************************************************************************
		
		private function onMouseDown(e:MouseEvent):void
		{
			
		}			
		
		private function onMouseUp(e:MouseEvent):void
		{
			if (active)
			{
				if (!CameraManager.hasMoved && !multiSelection && !currentGizmo.active) unselectAll();	
			}	
		}			
		
		//Change gizmo mode to transform the selected mesh
		public static function setTransformMode(mode:String):void
		{
			switch (mode) 
			{													
				case GizmoMode.TRANSLATE :
					
					currentGizmo.active = false;
					currentGizmo.hide();
					currentGizmo = translateGizmo;
					if (selectedObject) currentGizmo.show(selectedObject);
					
					break;				
				
				case GizmoMode.ROTATE:
					
					currentGizmo.active = false;
					currentGizmo.hide();
					currentGizmo = rotateGizmo;
					if (selectedObject) currentGizmo.show(selectedObject);
					
					break;				
				
				case GizmoMode.SCALE:
					
					currentGizmo.active = false;
					currentGizmo.hide();
					currentGizmo = scaleGizmo;
					if (selectedObject) currentGizmo.show(selectedObject);
					
					break;													
			}						
		}
		
		
		// Keyboard Events ************************************************************************************************************************************************
		
		private function onKeyDown(e:KeyboardEvent):void
		{
			switch (e.keyCode) 
			{					
				case Keyboard.F: 
					
					if (selectedObject != null) CameraManager.focusTarget(selectedObject);
					
					break;				
				
				case Keyboard.T: setTransformMode(GizmoMode.TRANSLATE);
										
					break;				
				
				case Keyboard.R: setTransformMode(GizmoMode.ROTATE);
					
					break;				
				
				case Keyboard.S: setTransformMode(GizmoMode.SCALE);
					
					break;					
				
				case Keyboard.CONTROL:
					
					multiSelection = true;
					
					break;								
			}			
		}
		
		private function onKeyUp(e:KeyboardEvent):void
		{
			switch (e.keyCode) 
			{									
				case Keyboard.CONTROL:
					
					multiSelection = false;
					
					break;
			}	
		}			
		
		
		
		
		
		// Lights Handling *********************************************************************************************************************************************
		
		public static function addLight(light:LightBase):void
		{
			var gizmo:LightGizmo3D = new LightGizmo3D(light); 
			gizmo.cone.addEventListener(MouseEvent3D.CLICK, instance.handleMouseEvent3D);
			light.addChild(gizmo);
			lightGizmos.addItem(gizmo);
			objects.addItem(light);
			
			scene.addChild(light);
			lights.addItem(light);
		}
		
		public static function removeLight(light:LightBase):void
		{
			scene.removeChild(light);
			
			for (var i:int=0;i<lights.length;i++)
			{
				if (lights[i] == light)
				{
					lights.removeItemAt(i);
					lightGizmos.removeItemAt(i);
					break;
				}
			}
		}	
		
		public static function addLightToMesh(mesh:Mesh, lightName:String):void
		{
			if (mesh.material) 
			{
				if (!mesh.material.lightPicker)	mesh.material.lightPicker = new StaticLightPicker([]);
			
				for each(var l:LightBase in lights.source)
				{
					if (l.name == lightName)
					{
						var meshLights:Array = StaticLightPicker(mesh.material.lightPicker).lights;
						meshLights.push(l);
						StaticLightPicker(mesh.material.lightPicker).lights = meshLights;
						break;
					}
				}			
			}
		}		
		
		public static function removeLightFromMesh(mesh:Mesh, lightName:String):void
		{
			if (mesh.material) 
			{
				if (mesh.material.lightPicker)
				{
					var meshLights:Array = StaticLightPicker(mesh.material.lightPicker).lights;
					
					for(var i:int=0;i<meshLights.length;i++)
					{
						if (meshLights[i].name == lightName)
						{
							meshLights.splice(i, 1);
							StaticLightPicker(mesh.material.lightPicker).lights = meshLights;
							break;
						}
					}
				}	
			}
		}			
		
		public static function getLightByName(lightName:String):LightBase
		{
			var light:LightBase;
			
			for each(var l:LightBase in lights.source)
			{
				if (l.name == lightName)
				{
					light = l;
					break;
				}
			}
			
			return light;
		}			
		
		
		// Meshes Handling *********************************************************************************************************************************************
		
		public static function addMesh(mesh:Mesh):void
		{			
			mesh.mouseEnabled = true;
			mesh.pickingCollider = PickingColliderType.AS3_BEST_HIT;
			mesh.addEventListener(MouseEvent3D.CLICK, instance.handleMouseEvent3D);			
			
			scene.addChild(mesh);
			
			objects.addItem(mesh);
		}		
		
		public static function removeMesh(mesh:Mesh):void
		{
			scene.removeChild(mesh);
			
			for (var i:int=0;i<objects.length;i++)
			{
				if (objects[i] == mesh)
				{
					objects.removeItemAt(i);
					//meshes.splice(i, 1);
					break;
				}
			}
		}
		
		public static function getObjectByName(mName:String):Entity
		{
			var mesh:Mesh;
			
			for each(var m:Mesh in objects.source)
			{
				if (m.name == mName)
				{
					mesh = m;
					break;
				}
			}
			
			return mesh;
		}		
		
		private function handleMouseEvent3D(e:Event):void 
		{
			if (!CameraManager.hasMoved && !currentGizmo.hasMoved && active)
			{
				if (Mesh(e.target).showBounds) unSelectObjectByName(e.target.name);
				else selectObjectByName(e.target.name);					
			}
		}					
		
		public static function unselectAll():void
		{
			for each(var m:Entity in objects.source)
			{
				m.showBounds = false;
			}
			
			selectedObjects = new ArrayList();
			selectedObject = null;
			currentGizmo.hide();
		}
		
		public static function unSelectObjectByName(meshName:String):void
		{
			for(var i:int=0;i<selectedObjects.length;i++)
			{
				var m:Entity = selectedObjects[i];
				if (m.name == meshName)
				{
					if (m is Mesh) m.showBounds = false;
					selectedObjects.removeItemAt(i);			
					selectedObject = selectedObjects[selectedObjects.length-1];
					
					break;
				}
			}			
		}		
		
		public static function selectObjectByName(meshName:String):void
		{			
			if (!multiSelection) unselectAll();
			
			for each(var m:Entity in objects.source)
			{
				if (m.name == meshName)
				{
					if (!m.showBounds)
					{
						if (m is Mesh) m.showBounds = true;
						selectedObjects.addItem(m);						
						selectedObject = m;
						currentGizmo.show(selectedObject);
					}

					break;
				}
			}
			
			instance.dispatchEvent(new Scene3DManagerEvent(Scene3DManagerEvent.MESH_SELECTED));
		}
		
	}
}