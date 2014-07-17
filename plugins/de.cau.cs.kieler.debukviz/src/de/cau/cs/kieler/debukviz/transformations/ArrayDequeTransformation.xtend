/*
 * DebuKViz - Kieler Debug Visualization
 * 
 * A part of OpenKieler
 * https://github.com/OpenKieler
 * 
 * Copyright 2014 by
 * + Christian-Albrechts-University of Kiel
 *   + Department of Computer Science
 *     + Real-Time and Embedded Systems Group
 * 
 * This code is provided under the terms of the Eclipse Public License (EPL).
 * See the file epl-v10.html for the license text.
 */
package de.cau.cs.kieler.debukviz.transformations

import com.google.inject.Inject
import de.cau.cs.kieler.core.krendering.extensions.KLabelExtensions
import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KPolylineExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.debukviz.AbstractVariableTransformation
import de.cau.cs.kieler.kiml.options.Direction
import de.cau.cs.kieler.kiml.options.EdgeLabelPlacement
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.util.KimlUtil
import org.eclipse.debug.core.model.IVariable

/**
 * Transformation for a variable which is representing a variable of type "ArrayDeque"
 */
class ArrayDequeTransformation extends AbstractVariableTransformation {
    
    @Inject
    extension KNodeExtensions 
    @Inject 
    extension KPolylineExtensions 
    @Inject 
    extension KLabelExtensions
    @Inject
    extension KRenderingExtensions
    
    // store the actual element to use it in the next iteration 
    var IVariable previous = null
    
    /**
     * Transformation for a variable which is representing a variable of type "ArrayDeque"
     * 
     * {@inheritDoc}
     */
    override transform(IVariable model, Object transformationInfo) {
        return KimlUtil::createInitializedNode() => [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.klay.layered")
            //it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization")
            it.addLayoutParam(LayoutOptions::SPACING, 50f)
            it.addLayoutParam(LayoutOptions::DIRECTION, Direction::RIGHT);
            
            it.data += renderingFactory.createKRectangle()
            
     		// Get necessary data
            val head = Integer::parseInt(model.getValue("head"));
            val tail = Integer::parseInt(model.getValue("tail"));
            val IVariable[] elements = model.getVariables("elements");
            if (head != tail) {
            	var int index = head;
	            // Iterate from element with index head to element with index tail
	            while (index <= tail) {
	                val variable = elements.get(index)
	                it.nextTransformation(variable)
	                
	                // Create a edge from previous to variable
	                if (previous != null) {
	                    val edge = previous.createEdgeById(variable) => [
	                        it.data += renderingFactory.createKPolyline() => [
	                            it.setLineWidth(2)
	                            it.addArrowDecorator();
	                        ]
	                    ]
	                    // Add "head" label to the first edge
	                    if (index == head+1)
	                        previous.createLabel(edge) => [
	                            it.text = "head";
	                            it.addLayoutParam(LayoutOptions::EDGE_LABEL_PLACEMENT, EdgeLabelPlacement::CENTER)
	                            it.setLabelSize(50,50)
	                        ]
	                    // Add "tail" label to the last edge
	                    if (index == tail)
	                        previous.createLabel(edge) => [
	                            it.text = "tail";
	                            it.addLayoutParam(LayoutOptions::EDGE_LABEL_PLACEMENT, EdgeLabelPlacement::CENTER)
	                            it.setLabelSize(50,50)
	                        ]
	                }
	                previous = variable
	                index = index + 1
	            }
            }
            else {
	         	it.children += createNode() => [
	         		it.setNodeSize(80,80)
	         		it.data += renderingFactory.createKRectangle() => [
	         			it.children += renderingFactory.createKText() => [
	         				it.text = "empty"
	         			]
	         		]
	         	]
	         }
        ]
    }
    

    override getNodeCount(IVariable model) {
        val head = Integer::parseInt(model.getValue("head"));
        val tail = Integer::parseInt(model.getValue("tail"));
        return tail - head + 1 
    }
    

}