package org.uqbar.project.wollok.interpreter.api

import org.uqbar.project.wollok.interpreter.WollokInterpreter
import org.uqbar.project.wollok.interpreter.WollokInterpreterEvaluator
import org.uqbar.project.wollok.interpreter.WollokRuntimeException
import org.uqbar.project.wollok.interpreter.operation.WollokBasicBinaryOperations
import org.uqbar.project.wollok.interpreter.operation.WollokDeclarativeNativeBasicOperations

/**
 * Gives access to some interpreter features which are needed to some Wollok objects to work properly.
 */
class WollokInterpreterAccess {
	WollokBasicBinaryOperations operations = new WollokDeclarativeNativeBasicOperations
	
	public static val INSTANCE = new WollokInterpreterAccess
	
	/**
	 * Helper method for simple access to wollok equality between objects, 
	 * which is needed in different parts of the interpreter 
	 */
	def boolean wollokEquals(Object a, Object b) {
		operations.asBinaryOperation("==").apply(a, [|b]).isTrue()
	}

	/**
	 * Helper method for simple access to wollok number comparison, 
	 * which is needed in different parts of the interpreter 
	 */
	def boolean wollokGreaterThan(Object a, Object b) {
		operations.asBinaryOperation(">").apply(a, [|b]).isTrue()
	}

	def dispatch boolean isTrue(Boolean b) { b }
	// I18N !
	def dispatch boolean isTrue(Object o) { throw new WollokRuntimeException('''Expected a boolean but find: «o»''') }

	// ********************************************************************************************
	// ** Conversions from native to wollok objects
	// ** REVIEWME: we have some other place in the code where we perform java-wollok translations 
	// ********************************************************************************************

	def <T> T asWollokObject(Object object) { object?.doAsWollokObject as T }
	def dispatch doAsWollokObject(Integer i) { evaluator.instantiateNumber(i.toString) }
	def dispatch doAsWollokObject(Double d) { evaluator.instantiateNumber(d.toString) }
	def dispatch doAsWollokObject(Object o) { o }
	
	def evaluator() {
		WollokInterpreter.getInstance.evaluator as WollokInterpreterEvaluator
	}
}
