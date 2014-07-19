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

import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.debukviz.VariableTransformation
import de.cau.cs.kieler.debukviz.VariableTransformationContext
import de.cau.cs.kieler.debukviz.util.EdgeBuilder
import de.cau.cs.kieler.debukviz.util.NodeBuilder
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.kiml.options.PortConstraints
import de.cau.cs.kieler.kiml.options.PortSide
import org.eclipse.debug.core.model.IVariable

/**
 * Transformation for a variable representing a runtime variable which is an array
 */
class ArrayTransformation extends VariableTransformation {
    
    override transform(IVariable variable, KNode graph, VariableTransformationContext context) {
        val listNode = NodeBuilder.forVariable(variable, graph, context)
                .type("Array")
                .addDefaultInputPort(PortSide::NORTH)
                .addLayoutOption(LayoutOptions::PORT_CONSTRAINTS, PortConstraints::FIXED_ORDER)
                .build()
        variable.value.variables.forEach[ element, index |
            invokeFor(element, graph, context)
            val elementNode = context.findAssociation(element)
            if (elementNode != null) {
                EdgeBuilder.forContext(context)
                        .from(listNode)
                        .addSourcePort(PortSide::SOUTH, -index)
                        .to(elementNode)
                        .tailLabel(index.toString)
                        .build()
            } else {
                EdgeBuilder.makePort(PortSide::SOUTH, -index).setNode(listNode)
            }
        ]
    }
   
}