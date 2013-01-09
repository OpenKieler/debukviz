package de.cau.cs.kieler.klighd.debug.transformations

import de.cau.cs.kieler.klighd.debug.transformations.AbstractKNodeTransformation
import de.cau.cs.kieler.core.kgraph.KNode
import de.cau.cs.kieler.klighd.TransformationContext
import org.eclipse.debug.core.model.IVariable
import de.cau.cs.kieler.core.krendering.extensions.KNodeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KEdgeExtensions
import de.cau.cs.kieler.core.krendering.extensions.KRenderingExtensions
import de.cau.cs.kieler.core.krendering.extensions.KColorExtensions
import de.cau.cs.kieler.core.krendering.KRenderingFactory
import de.cau.cs.kieler.kiml.util.KimlUtil
import de.cau.cs.kieler.kiml.options.LayoutOptions
import de.cau.cs.kieler.core.krendering.KContainerRendering

class LNodeTransformation extends AbstractKNodeTransformation {

    extension KNodeExtensions kNodeExtensions = new KNodeExtensions()
    extension KEdgeExtensions kEdgeExtensions = new KEdgeExtensions()
    extension KRenderingExtensions kRenderingExtensions = new KRenderingExtensions()
    extension KColorExtensions kColorExtensions = new KColorExtensions()
    
    
    private static val KRenderingFactory renderingFactory = KRenderingFactory::eINSTANCE

    //TODO: create ports
    //TODO: add all labels

    /**
     * Create a representation of a LNode
     * @param rootNode The KNode this node is placed into
     * @param variable The IVariable containing the data for this LNode
     */
    override transform(IVariable variable, TransformationContext<IVariable,KNode> transformationContext) {
        use(transformationContext)

        return KimlUtil::createInitializedNode => [
            it.addLayoutParam(LayoutOptions::ALGORITHM, "de.cau.cs.kieler.kiml.ogdf.planarization")
            it.addLayoutParam(LayoutOptions::SPACING, 75f)
                
            it.children += variable.createNode().putToLookUpWith(variable) => [
                
                // Get the nodeType
                val nodeType = variable.nodeType
                // Get the ports
                val ports = variable.getVariableByName("ports").linkedList
                // Get the labels
                val labels = variable.getVariableByName("labels").linkedList
                
                /*
                 * Normal nodes. (If nodeType is null, the default type is taken, which is "NORMAL")
                 *  - show their name (if set) or their node ID
                 *  - are represented by an rectangle  
                 */ 
                if (nodeType == "NORMAL" ) {
                    it.data += renderingFactory.createKRectangle => [
                        it.lineWidth = 2 
                        it.setBackgroundColor(variable)
                        it.ChildPlacement = renderingFactory.createKGridPlacement                    
                        
                        // Name of the node is the first label
                        it.children += renderingFactory.createKText => [
                            if(labels.isEmpty) {
                                // no name given
                                it.setText("name: -")
                            } else {
                                it.setText("name: " + labels.get(0).getValueByName("text"))
                            }
                        ]
                    ]
                } else {
                    /*
                     * Dummy nodes.
                     *  - show their name (if set) or their node ID
                     *  - are represented by an ellipses  
                     */
                    it.data += renderingFactory.createKEllipse => [
                        it.lineWidth = 2
                        it.setBackgroundColor(variable)
                        it.ChildPlacement = renderingFactory.createKGridPlacement
                        // Name of the node is the first label
                        it.children += renderingFactory.createKText => [
                            if(labels.isEmpty) {
                                // no name given, so display the node id instead
                                it.setText("nodeID: " + variable.getValueByName("id"))
                            } else {
                                it.setText("name: " + labels.get(0).getValueByName("text"))
                            }
                            if (nodeType == "NORTH_SOUTH_PORT") {
                                val origin = variable.getVariableByName("propertyMap").getKeyFromHashMap("origin")
                                if (origin.getType == "LNode") {
                                    it.children += renderingFactory.createKText => [
                                        it.setText("Origin: " + origin.getVariableByName("labels").linkedList.get(0))
                                    ]   
                                }
                            }
                        ]
                    ]
                }
            ]
        ]
    }
    
    def setBackgroundColor(KContainerRendering rendering, IVariable variable) {
       /*
        *  original values from de.cau.cs.kieler.klay.layered.properties.NodeType:
        *  case "COMPOUND_SIDE": return "#808080"
        *  case "EXTERNAL_PORT": return "#cc99cc"
        *  case "LONG_EDGE": return "#eaed00"
        *  case "NORTH_SOUTH_PORT": return "#0034de"
        *  case "LOWER_COMPOUND_BORDER": return "#18e748"
        *  case "LOWER_COMPOUND_PORT": return "#2f6d3e"
        *  case "UPPER_COMPOUND_BORDER": return "#fb0838"
        *  case "UPPER_COMPOUND_PORT": return "#b01d38"
        *  default: return "#000000"
        *  coding: #RGB", where each component is given as a two-digit hexadecimal value.
        */
        switch (getNodeType(variable)) {
            case "COMPOUND_SIDE": rendering.setBackgroundColor(128,128,128)
            case "EXTERNAL_PORT": rendering.setBackgroundColor(204,153,204)
            case "LONG_EDGE": rendering.setBackgroundColor(234,237,0)
            case "NORTH_SOUTH_PORT": rendering.setBackgroundColor(0,52,222)
            case "LOWER_COMPOUND_BORDER": rendering.setBackgroundColor(24,231,72)
            case "LOWER_COMPOUND_PORT": rendering.setBackgroundColor(47,109,62)
            case "UPPER_COMPOUND_BORDER": rendering.setBackgroundColor(251,8,56)
            case "UPPER_COMPOUND_PORT": rendering.setBackgroundColor(176,29,56)
            default: return rendering.setBackgroundColor(255,255,255)
        }
    }
    
    def getNodeType(IVariable variable) {
        val type = variable.getVariableByName("propertyMap").getKeyFromHashMap("nodeType")
        if (type == null) {
            return "NORMAL"
        } else {
            return type.getValueByName("name")   
        }
    }
}