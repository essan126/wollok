package org.uqbar.project.wollok.interpreter.core

import java.util.Map
import org.uqbar.project.wollok.interpreter.WollokInterpreterConsole
import org.uqbar.project.wollok.interpreter.context.EvaluationContext
import org.uqbar.project.wollok.interpreter.context.UnresolvableReference
import org.uqbar.project.wollok.interpreter.context.WVariable
import org.uqbar.project.wollok.interpreter.nativeobj.AbstractWollokDeclarativeNativeObject
import org.uqbar.project.wollok.interpreter.nativeobj.NativeMessage
import org.uqbar.project.wollok.interpreter.WollokInterpreter

/**
 * Contiene metodos "nativos" que están disponibles
 * para todo script como funciones de "this" (aunque solo 
 * a nivel root del archivo. Es decir que estas funciones
 * no están disponibles dentro de un objeto).
 * 
 * @author jfernandes
 */
class WollokNativeLobby extends AbstractWollokDeclarativeNativeObject implements EvaluationContext {
	var Map<String,Object> localVariables = newHashMap
	WollokInterpreterConsole console
	WollokInterpreter interpreter
	
	new(WollokInterpreterConsole console, WollokInterpreter interpreter) {
		this.console = console
		this.interpreter = interpreter
	}
	
	override getThisObject() { this }
	
	override allReferenceNames() {
		localVariables.keySet.map[new WVariable(it, true)]
	}
	
	override resolve(String variableName) throws UnresolvableReference {
		if (!localVariables.containsKey(variableName)){
			if(!interpreter.globalVariables.containsKey(variableName))
				throw new UnresolvableReference('''Cannot resolve reference «variableName»''')
			else
				interpreter.globalVariables.get(variableName)
		}else
			localVariables.get(variableName)
	}
	
	override setReference(String variableName, Object value) {
		if (!localVariables.containsKey(variableName)){
			if(!interpreter.globalVariables.containsKey(variableName))
				throw new UnresolvableReference('''Cannot resolve reference «variableName»''')
			else
				interpreter.globalVariables.put(variableName,value)
		}else
			localVariables.put(variableName,value)
	}
	
	override addReference(String name, Object value) {
		localVariables.put(name, value)
		value
	}
	
	// ******************************
	// ** native
	// ******************************
	
	def println(Object args) {
		console.logMessage("" + args)
	}
	
	def sleep(Integer milis) {
		Thread.sleep(milis)
	}
	
	override addGlobalReference(String name, Object value) {
		interpreter.globalVariables.put(name,value)
		value
	}

	@NativeMessage("assert")
	def assertMethod(Boolean value) {
		if (!value) 
			throw new AssertionError("Value was not true")
	}
	
	def assertFalse(Boolean value) {
		if (value) 
			throw new AssertionError("Value was not false")
	}
	
	def assertEquals(Object a, Object b) {
		// TODO: debería compararlos usando el intérprete, como si el usuario mismo
		// hubiera escrito "a != b". Sino acá está comparando según Java por identidad.
		if (a != b)
			throw new AssertionError('''Expected [«a»] but found [«b»]''')
	}
}