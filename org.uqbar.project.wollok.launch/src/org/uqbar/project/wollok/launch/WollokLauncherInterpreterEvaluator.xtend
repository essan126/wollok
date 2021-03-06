package org.uqbar.project.wollok.launch

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtend.lib.annotations.Accessors
import org.uqbar.project.wollok.interpreter.WollokInterpreter
import org.uqbar.project.wollok.interpreter.WollokInterpreterEvaluator
import org.uqbar.project.wollok.interpreter.core.WollokObject
import org.uqbar.project.wollok.launch.tests.WollokTestsReporter
import org.uqbar.project.wollok.wollokDsl.WFile
import org.uqbar.project.wollok.wollokDsl.WSuite
import org.uqbar.project.wollok.wollokDsl.WTest

import static extension org.uqbar.project.wollok.launch.tests.WollokExceptionUtils.*
import static extension org.uqbar.project.wollok.model.WMethodContainerExtensions.*

/**
 * 
 * Subclasses the wollok evaluator to support tests
 * 
 * @author tesonep
 * @author dodain -- describe development
 * 
 */
class WollokLauncherInterpreterEvaluator extends WollokInterpreterEvaluator {

	@Inject @Accessors
	WollokTestsReporter wollokTestsReporter

	// EVALUATIONS (as multimethods)
	override dispatch evaluate(WFile it) {
		// Files are not allowed to have both a main program and tests at the same time.
		if (main !== null)
			main.eval
		else {
			val _isASuite = isASuite
			var testsToRun = tests
			var String suiteName = null
			if (_isASuite) {
				suiteName = suite.name
				testsToRun = suite.tests
			}
			wollokTestsReporter.testsToRun(suiteName, it, testsToRun)
			try {
				testsToRun.fold(null) [ a, _test |
					resetGlobalState
					if (_isASuite) {
						_test.evalInSuite(suite)
					} else {
						_test.eval
					}
				]
			} finally {
				wollokTestsReporter.finished
			}
		}
	}

	override evaluateAll(List<EObject> eObjects, String folder) {
		wollokTestsReporter.initProcessManyFiles(folder)
		val result = eObjects.fold(null, [ o, eObject |
			interpreter.initStack
			interpreter.generateStack(eObject)		 
			evaluate(eObject as WFile)
		])
		wollokTestsReporter.endProcessManyFiles
		result
	}
	
	def WollokObject evalInSuite(WTest test, WSuite suite) {
		// If in a suite, we should create a suite wko so this will be our current context to eval the tests
		try {
			val suiteObject = new SuiteBuilder(suite, interpreter).forTest(test).build
			interpreter.performOnStack(test, suiteObject, [ | test.eval])
		} catch (Exception e) {
			handleExceptionInTest(e, test)
		} 
	}

	def resetGlobalState() {
		interpreter.globalVariables.clear
	}

	override dispatch evaluate(WTest test) {
		try {
			// wollokTestsReporter.testStart(test)
			val testResult = test.elements.evalAll
			wollokTestsReporter.reportTestOk(test)
			testResult
		} catch (Exception e) {
			handleExceptionInTest(e, test)
		}
	}
	
	protected def WollokObject handleExceptionInTest(Exception e, WTest test) {
		if (e.isAssertionException) {
			wollokTestsReporter.reportTestAssertError(test, e.generateAssertionError, e.lineNumber, e.URI)
			null
		} else {
			wollokTestsReporter.reportTestError(test, e, e.lineNumber, e.URI)
			null
		}
	}

}

class SuiteBuilder {
	WSuite suite
	WTest test
	WollokInterpreter interpreter

	new(WSuite suite, WollokInterpreter interpreter) {
		this.suite = suite
		this.interpreter = interpreter
	}

	def forTest(WTest test) {
		this.test = test
		this
	}

	def build() {
		// Suite -> suite wko  
		val suiteObject = new WollokObject(interpreter, suite)
		// Declaring suite variables as suite wko instance variables
		suite.members.forEach [ member |
			suiteObject.addMember(member)
		]
		if (suite.fixture !== null) {
			suite.fixture.elements.forEach [ element |
				interpreter.performOnStack(test, suiteObject, [| interpreter.eval(element) ])
			]
		}		
		if (test !== null) {
			// Now, declaring test local variables as suite wko instance variables
			test.variableDeclarations.forEach[ variable |
				suiteObject.addMember(variable)
			]
		}
		suiteObject
	}

}
